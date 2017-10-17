import Transformer from require "moonscript.transform.transformer"

import NameProxy, LocalName, is_name_proxy from require "moonscript.transform.names"

import Run, transform_last_stm, implicitly_return, last_stm
  from require "moonscript.transform.statements"

types = require "moonscript.types"

import build, ntype, is_value, smart_node, value_is_singular, is_slice, NOOP
  from types

import insert from table

destructure = require "moonscript.transform.destructure"
import construct_comprehension from require "moonscript.transform.comprehension"

import unpack from require "moonscript.util"

with_continue_listener = (body) ->
  continue_name = nil

  {
    Run =>
      @listen "continue", ->
        unless continue_name
          continue_name = NameProxy"continue"
          @put_name continue_name
        continue_name

    build.group body

    Run =>
      return unless continue_name
      last = last_stm body
      enclose_lines = types.terminating[last and ntype(last)]

      @put_name continue_name, nil
      @splice (lines) ->
        lines = {"do", {lines}} if enclose_lines

        {
          {"assign", {continue_name}, {"false"}}
          {"repeat", "true", {
            lines
            {"assign", {continue_name}, {"true"}}
          }}
          {"if", {"not", continue_name}, {
            {"break"}
          }}
        }
  }


-- this mutates body searching for assigns
extract_declarations = (body=@current_stms, start=@current_stm_i + 1, out={}) =>
  for i=start,#body
    stm = body[i]
    continue if stm == nil
    stm = @transform.statement stm
    body[i] = stm
    switch stm[1]
      when "assign", "declare"
        for name in *stm[2]
          if ntype(name) == "ref"
            insert out, name
          elseif type(name) == "string"
            -- TODO: don't use string literal as ref
            insert out, name
      when "group"
        extract_declarations @, stm[2], 1, out
  out

expand_elseif_assign = (ifstm) ->
  for i = 4, #ifstm
    case = ifstm[i]
    if ntype(case) == "elseif" and ntype(case[2]) == "assign"
      split = { unpack ifstm, 1, i - 1 }
      insert split, {
        "else", {
          {"if", case[2], case[3], unpack ifstm, i + 1}
        }
      }
      return split

  ifstm


Transformer {
  transform: (tuple) =>
    {_, node, fn} = tuple
    fn node

  root_stms: (body) =>
    transform_last_stm body, implicitly_return @

  return: (node) =>
    ret_val = node[2]
    ret_val_type = ntype ret_val

    if ret_val_type == "explist" and #ret_val == 2
      ret_val = ret_val[2]
      ret_val_type = ntype ret_val

    if types.cascading[ret_val_type]
      return implicitly_return(@) ret_val

    -- flatten things that create block exp
    if ret_val_type == "chain" or ret_val_type == "comprehension" or ret_val_type == "tblcomprehension"
      -- TODO: clean this up
      Value = require "moonscript.transform.value"
      ret_val = Value\transform_once @, ret_val
      if ntype(ret_val) == "block_exp"
        return build.group transform_last_stm ret_val[2], (stm)->
            {"return", stm}

    node[2] = ret_val
    node

  declare_glob: (node) =>
    names = extract_declarations @

    if node[2] == "^"
      names = for name in *names
        str_name = if ntype(name) == "ref"
          name[2]
        else
          name

        continue unless str_name\match "^%u"
        name

    {"declare", names}

  assign: (node) =>
    names, values = unpack node, 2

    num_values = #values
    num_names = #values

    -- special code simplifications for single assigns
    if num_names == 1 and num_values == 1
      first_value = values[1]
      first_name = names[1]
      first_type = ntype first_value

      -- reduce colon stub chain to block exp
      if first_type == "chain"
        -- TODO: clean this up
        Value = require "moonscript.transform.value"
        first_value = Value\transform_once @, first_value
        first_type = ntype first_value

      switch ntype first_value
        when "block_exp"
          block_body = first_value[2]
          idx = #block_body
          block_body[idx] = build.assign_one first_name, block_body[idx]

          return build.group {
            {"declare", {first_name}}
            {"do", block_body}
          }

        when "comprehension", "tblcomprehension", "foreach", "for", "while"
          -- TODO: clean this up
          Value = require "moonscript.transform.value"
          return build.assign_one first_name, Value\transform_once @, first_value
        else
          values[1] = first_value

    -- bubble cascading assigns
    transformed = if num_values == 1
      value = values[1]
      t = ntype value

      if t == "decorated"
        value = @transform.statement value
        t = ntype value

      if types.cascading[t]
        ret = (stm) ->
          if is_value stm
            {"assign", names, {stm}}
          else
            stm

        build.group {
          {"declare", names}
          @transform.statement value, ret, node
        }

    node = transformed or node

    if destructure.has_destructure names
      return destructure.split_assign @, node

    node

  continue: (node) =>
    continue_name = @send "continue"
    error "continue must be inside of a loop" unless continue_name
    build.group {
      build.assign_one continue_name, "true"
      {"break"}
    }

  export: (node) =>
    -- assign values if they are included
    if #node > 2
      if node[2] == "class"
        cls = smart_node node[3]
        build.group {
          {"export", {cls.name}}
          cls
        }
      else
        -- pull out vawlues and assign them after the export
        build.group {
          { "export", node[2] }
          build.assign {
            names: node[2]
            values: node[3]
          }
        }
    else
      nil

  update: (node) =>
    name, op, exp = unpack node, 2
    op_final = op\match "^(.+)=$"

    error "Unknown op: "..op if not op_final

    local lifted

    if ntype(name) == "chain"
      lifted = {}
      new_chain = for part in *name[3,]
        if ntype(part) == "index"
          proxy = NameProxy "update"
          table.insert lifted, { proxy, part[2] }
          { "index", proxy }
        else
          part

      if next lifted
        name = {name[1], name[2], unpack new_chain}

    exp = {"parens", exp} unless value_is_singular exp
    out = build.assign_one name, {"exp", name, op_final, exp}

    if lifted and next lifted
      names = [l[1] for l in *lifted]
      values = [l[2] for l in *lifted]

      out = build.group {
        {"assign", names, values}
        out
      }

    out

  import: (node) =>
    names, source = unpack node, 2
    table_values = for name in *names
      dest_name = if ntype(name) == "colon"
        name[2]
      else
        name

      {{"key_literal", name}, dest_name}

    dest = { "table", table_values }
    { "assign", {dest}, {source}, [-1]: node[-1] }

  comprehension: (node, action) =>
    exp, clauses = unpack node, 2

    action = action or (exp) -> {exp}
    construct_comprehension action(exp), clauses

  do: (node, ret) =>
    node[2] = transform_last_stm node[2], ret if ret
    node

  decorated: (node) =>
    stm, dec = unpack node, 2

    wrapped = switch dec[1]
      when "if"
        cond, fail = unpack dec, 2
        fail = { "else", { fail } } if fail
        { "if", cond, { stm }, fail }
      when "unless"
        { "unless", dec[2], { stm } }
      when "comprehension"
        { "comprehension", stm, dec[2] }
      else
        error "Unknown decorator " .. dec[1]

    if ntype(stm) == "assign"
      wrapped = build.group {
        build.declare names: [name for name in *stm[2] when ntype(name) == "ref"]
        wrapped
      }

    wrapped

  unless: (node) =>
    clause = node[2]

    if ntype(clause) == "assign"
      if destructure.has_destructure clause[2]
        error "destructure not allowed in unless assignment"

      build.do {
        clause
        { "if", {"not", clause[2][1]}, unpack node, 3 }
      }

    else
      { "if", {"not", {"parens", clause}}, unpack node, 3 }

  if: (node, ret) =>
    -- expand assign in cond
    if ntype(node[2]) == "assign"
      assign, body = unpack node, 2
      if destructure.has_destructure assign[2]
        name = NameProxy "des"

        body = {
          destructure.build_assign @, assign[2][1], name
          build.group node[3]
        }

        return build.do {
          build.assign_one name, assign[3][1]
          {"if", name, body, unpack node, 4}
        }
      else
        name = assign[2][1]
        return build.do {
          assign
          {"if", name, unpack node, 3}
        }

    node = expand_elseif_assign node

    -- apply cascading return decorator
    if ret
      smart_node node
      -- mutate all the bodies
      node['then'] = transform_last_stm node['then'], ret
      for i = 4, #node
        case = node[i]
        body_idx = #node[i]
        case[body_idx] = transform_last_stm case[body_idx], ret

    node

  with: (node, ret) =>
    exp, block = unpack node, 2

    copy_scope = true
    local scope_name, named_assign

    if last = last_stm block
      ret = false if types.terminating[ntype(last)]

    if ntype(exp) == "assign"
      names, values = unpack exp, 2
      first_name = names[1]

      if ntype(first_name) == "ref"
        scope_name = first_name
        named_assign = exp
        exp = values[1]
        copy_scope = false
      else
        scope_name = NameProxy "with"
        exp = values[1]
        values[1] = scope_name
        named_assign = {"assign", names, values}

    elseif @is_local exp
      scope_name = exp
      copy_scope = false

    scope_name or= NameProxy "with"

    out = build.do {
      copy_scope and build.assign_one(scope_name, exp) or NOOP
      named_assign or NOOP
      Run => @set "scope_var", scope_name
      unpack block
    }

    if ret
      table.insert out[2], ret scope_name

    out

  foreach: (node, _) =>
    smart_node node
    source = unpack node.iter

    destructures = {}
    node.names = for i, name in ipairs node.names
      if ntype(name) == "table"
        with proxy = NameProxy "des"
          insert destructures, destructure.build_assign @, name, proxy
      else
        name

    if next destructures
      insert destructures, build.group node.body
      node.body = destructures

    if ntype(source) == "unpack"
      list = source[2]

      index_name = NameProxy "index"

      list_name = @is_local(list) and list or NameProxy "list"

      slice_var = nil
      bounds = if is_slice list
        slice = list[#list]
        table.remove list
        table.remove slice, 1

        list_name = list if @is_local list

        slice[2] = if slice[2] and slice[2] != ""
          max_tmp_name = NameProxy "max"
          slice_var = build.assign_one max_tmp_name, slice[2]
          {"exp", max_tmp_name, "<", 0
            "and", {"length", list_name}, "+", max_tmp_name
            "or", max_tmp_name }
        else
          {"length", list_name}

        slice
      else
        {1, {"length", list_name}}

      names = [is_name_proxy(n) and n or LocalName(n) or n for n in *node.names]

      return build.group {
        list_name != list and build.assign_one(list_name, list) or NOOP
        slice_var or NOOP
        build["for"] {
          name: index_name
          bounds: bounds
          body: {
            {"assign", names, { NameProxy.index list_name, index_name }}
            build.group node.body
          }
        }
      }

    node.body = with_continue_listener node.body

  while: (node) =>
    smart_node node
    node.body = with_continue_listener node.body

  for: (node) =>
    smart_node node
    node.body = with_continue_listener node.body

  switch: (node, ret) =>
    exp, conds = unpack node, 2
    exp_name = NameProxy "exp"

    -- convert switch conds into if statment conds
    convert_cond = (cond) ->
      t, case_exps, body = unpack cond
      out = {}
      insert out, t == "case" and "elseif" or "else"
      if  t != "else"
        cond_exp = {}
        for i, case in ipairs case_exps
          if i == 1
            insert cond_exp, "exp"
          else
            insert cond_exp, "or"

          case = {"parens", case} unless value_is_singular case
          insert cond_exp, {"exp", case, "==", exp_name}

        insert out, cond_exp
      else
        body = case_exps

      if ret
        body = transform_last_stm body, ret

      insert out, body

      out

    first = true
    if_stm = {"if"}
    for cond in *conds
      if_cond = convert_cond cond
      if first
        first = false
        insert if_stm, if_cond[2]
        insert if_stm, if_cond[3]
      else
        insert if_stm, if_cond

    build.group {
      build.assign_one exp_name, exp
      if_stm
    }

  class: require "moonscript.transform.class"
    
}
