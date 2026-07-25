import Transformer from require "moonscript.transform.transformer"
import build, ntype, smart_node from require "moonscript.types"

import NameProxy from require "moonscript.transform.names"
import Accumulator, default_accumulator from require "moonscript.transform.accumulator"
import lua_keywords from require "moonscript.data"
import user_error from require "moonscript.errors"

import transform_last_stm, implicitly_return, chain_is_stub, has_varargs from require "moonscript.transform.statements"

import construct_comprehension from require "moonscript.transform.comprehension"
destructure = require "moonscript.transform.destructure"

import insert from table
import unpack from require "moonscript.util"

Transformer {
  for: default_accumulator
  while: default_accumulator
  foreach: default_accumulator

  do: (node) =>
    build.block_exp node[2]

  decorated: (node) =>
    @transform.statement node

  class: (node) =>
    build.block_exp { node }

  string: (node) =>
    delim = node[2]

    convert_part = (part) ->
      if type(part) == "string" or part == nil
        {"string", delim, part or ""}
      else
        build.chain { base: "tostring", {"call", {part[2]}} }

    -- reduced to single item
    if #node <= 3
      return if type(node[3]) == "string"
        node
      else
        convert_part node[3]

    e = {"exp", convert_part node[3]}

    for i=4, #node
      insert e, ".."
      insert e, convert_part node[i]
    e

  comprehension: (node) =>
    a = Accumulator!
    node = @transform.statement node, (exp) ->
      a\mutate_body {exp}
    a\wrap node

  tblcomprehension: (node) =>
    explist, clauses = unpack node, 2
    key_exp, value_exp = unpack explist

    accum = NameProxy "tbl"

    inner = if value_exp
      dest = build.chain { base: accum, {"index", key_exp} }
      { build.assign_one dest, value_exp }
    else
      -- If we only have single expression then
      -- unpack the result into key and value
      key_name, val_name = NameProxy"key", NameProxy"val"
      dest = build.chain { base: accum, {"index", key_name} }
      {
        build.assign names: {key_name, val_name}, values: {key_exp}
        build.assign_one dest, val_name
      }

    build.block_exp {
      build.assign_one accum, build.table!
      construct_comprehension inner, clauses
      accum
    }

  fndef: (node) =>
    smart_node node
    node.body = transform_last_stm node.body, implicitly_return self

    -- from the first destructuring arg onward, argument initialization
    -- (default checks, self assigns, unpacking) moves into the body in left
    -- to right order, so a later default can reference an earlier
    -- destructured name:
    --   f = ({:a}, b = a) -> b
    -- earlier args stay on the compiler's default handling, keeping output
    -- for functions without destructuring unchanged
    local first_destructure
    for i, arg in ipairs node.args
      if ntype(arg[1]) == "table"
        first_destructure = i
        break

    if first_destructure
      -- a destructured name always shadows at the top of the body, so a
      -- later parameter of the same name could never be seen. reject the
      -- duplicate instead of silently breaking later-parameter-wins
      bound_names = {}
      -- fat arrow binds self as an implicit first parameter
      bound_names.self = true if node.arrow == "fat"
      for arg in *node.args
        switch ntype arg[1]
          when "self", "self_class"
            bound_names[arg[1][2]] = true
          when "table"
            nil
          else
            bound_names[arg[1]] = true if type(arg[1]) == "string"

      seen_targets = {}
      for arg in *node.args
        continue unless ntype(arg[1]) == "table"
        targets = [t for {t} in *destructure.extract_assign_names arg[1] when ntype(t) == "ref"]

        for target in *targets
          name = target[2]
          if bound_names[name] or seen_targets[name]
            user_error "Can't destructure into '#{name}': name is bound by another parameter", target[-1]

        for target in *targets
          seen_targets[target[2]] = true

      default_check = (name, value) ->
        {"if", {"exp", name, "==", "nil"}, {{"assign", {name}, {value}}}}

      prelude = {}
      for i=first_destructure, #node.args
        arg = node.args[i]
        name, default_value = arg[1], arg[2]

        switch ntype name
          when "table"
            proxy = NameProxy "arg"
            if default_value
              insert prelude, default_check proxy, default_value
            insert prelude, destructure.build_assign @, name, proxy, shadow: true
            node.args[i] = {proxy}
          when "self", "self_class"
            raw_name = name[2]
            if default_value
              insert prelude, default_check {"ref", raw_name}, default_value
            insert prelude, build.assign_one name, {"ref", raw_name}
            node.args[i] = {raw_name}
          else
            if default_value
              insert prelude, default_check {"ref", name}, default_value
              node.args[i] = {name}

      insert prelude, build.group node.body
      node.body = prelude

    node

  if: (node) =>
    build.block_exp { node }

  unless: (node) =>
    build.block_exp { node }

  with: (node) =>
    build.block_exp { node }

  switch: (node) =>
    build.block_exp { node }

  -- pull out colon chain
  chain: (node) =>
    -- escape lua keywords used in dot accessors
    for i=2,#node
      part = node[i]
      if ntype(part) == "dot" and lua_keywords[part[2]]
        node[i] = { "index", {"string", '"', part[2]} }

    if ntype(node[2]) == "string"
      -- add parens if callee is raw string
      node[2] = {"parens", node[2] }

    if chain_is_stub node
      base_name = NameProxy "base"
      fn_name = NameProxy "fn"
      colon = table.remove node

      -- a stub with no base takes the scope from the enclosing with block
      unless node[2]
        scope_var = @get "scope_var"
        unless scope_var
          user_error "Short-colon syntax must be called within a with block", node[-1]
        node[2] = scope_var

      is_super = ntype(node[2]) == "ref" and node[2][2] == "super"
      build.block_exp {
        build.assign {
          names: {base_name}
          values: {node}
        }

        build.assign {
          names: {fn_name}
          values: {
            build.chain { base: base_name, {"dot", colon[2]} }
          }
        }

        build.fndef {
          args: {{"..."}}
          body: {
            build.chain {
              base: fn_name, {"call", {is_super and "self" or base_name, "..."}}
            }
          }
        }
      }

  block_exp: (node) =>
    body = unpack node, 2

    arg_list = {}
    fn = smart_node build.fndef body: body

    -- if the body references varargs then the wrapper function must accept
    -- and forward them so they remain visible
    if has_varargs body
      insert arg_list, "..."
      insert fn.args, {"..."}

    build.chain { base: {"parens", fn}, {"call", arg_list} }
}

