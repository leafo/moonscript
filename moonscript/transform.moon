
module "moonscript.transform", package.seeall

types = require "moonscript.types"
util = require "moonscript.util"
data = require "moonscript.data"

import reversed from util
import ntype, build, smart_node, is_slice from types
import insert from table

export Statement, Value, NameProxy, Run

-- TODO refactor
is_value = (stm) ->
  moonscript.compile.Block\is_value(stm) or Value.can_transform stm

class NameProxy
  new: (@prefix) =>
    self[1] = "temp_name"

  get_name: (scope) =>
    if not @name
      @name = scope\free_name @prefix, true
    @name

  chain: (...) =>
    items = {...} -- todo: fix ... propagation
    items = for i in *items
      if type(i) == "string"
        {"dot", i}
      else
        i

    build.chain {
      base: self
      unpack items
    }

  index: (key) =>
    build.chain {
      base: self, {"index", key}
    }

  __tostring: =>
    if @name
      ("name<%s>")\format @name
    else
      ("name<prefix(%s)>")\format @prefix

class Run
  new: (@fn) =>
    self[1] = "run"

  call: (state) =>
    self.fn state

-- transform the last stm is a list of stms
-- will puke on group
apply_to_last = (stms, fn) ->
  -- find last (real) exp
  last_exp_id = 0
  for i = #stms, 1, -1
    stm = stms[i]
    if stm and util.moon.type(stm) != Run
      last_exp_id = i
      break

  return for i, stm in ipairs stms
    if i == last_exp_id
      fn stm
    else
      stm

-- is a body a sindle expression/statement
is_singular = (body) ->
  return false if #body != 1
  if "group" == ntype body
    is_singular body[2]
  else
    true

constructor_name = "new"

Transformer = (transformers) ->
  -- this is bad, instance it for compiler
  seen_nodes = {}
  tf = {
    transform: (n, ...) ->
      return n if seen_nodes[n]
      seen_nodes[n] = true
      while true
        transformer = transformers[ntype n]
        res = if transformer
          transformer(n, ...) or n
        else
          n
        return n if res == n
        n = res
    can_transform: (node) ->
      transformers[ntype node] != nil
  }

  setmetatable tf, {
    __call: (...) => self.transform ...
  }

Statement = Transformer {
  assign: (node) ->
    _, names, values = unpack node
    -- bubble cascading assigns
    if #values == 1 and types.cascading[ntype values[1]]
      values[1] = Statement values[1], (stm) ->
        t = ntype stm
        if is_value stm
          {"assign", names, {stm}}
        else
          stm

      build.group {
        {"declare", names}
        values[1]
      }
    else
      node

  export: (node) ->
    -- assign values if they are included
    if #node > 2
      if node[2] == "class"
        cls = smart_node node[3]
        build.group {
          {"export", {cls.name}}
          cls
        }
      else
        build.group {
          node
          build.assign {
            names: node[2]
            values: node[3]
          }
        }
    else
      nil

  update: (node) ->
    _, name, op, exp = unpack node
    op_final = op\match "^(.+)=$"
    error "Unknown op: "..op if not op_final
    build.assign_one name, {"exp", name, op_final, exp}

  import: (node) ->
    _, names, source = unpack node

    stubs = for name in *names
      if type(name) == "table"
        name
      else
        {"dot", name}

    real_names = for name in *names
      type(name) == "table" and name[2] or name

    if type(source) == "string"
      build.assign {
        names: real_names
        values: [build.chain { base: source, stub} for stub in *stubs]
      }
    else
      source_name = NameProxy "table"
      build.group {
        {"declare", real_names}
        build["do"] {
          build.assign_one source_name, source
          build.assign {
            names: real_names
            values: [build.chain { base: source_name, stub} for stub in *stubs]
          }
        }
      }

  comprehension: (node, action) ->
    _, exp, clauses = unpack node

    action = action or (exp) -> {exp}

    current_stms = action exp
    for _, clause in reversed clauses
      t = clause[1]
      current_stms = if t == "for"
        _, names, iter = unpack clause
        {"foreach", names, iter, current_stms}
      elseif t == "when"
        _, cond = unpack clause
        {"if", cond, current_stms}
      else
        error "Unknown comprehension clause: "..t
      current_stms = {current_stms}

    current_stms[1]

  -- handle cascading return decorator
  if: (node, ret) ->
    if ret
      smart_node node
      -- mutate all the bodies
      node['then'] = apply_to_last node['then'], ret
      for i = 4, #node
        case = node[i]
        body_idx = #node[i]
        case[body_idx] = apply_to_last case[body_idx], ret
    node

  with: (node, ret) ->
    _, exp, block = unpack node
    scope_name = NameProxy "with"
    build["do"] {
      build.assign_one scope_name, exp
      Run => @set "scope_var", scope_name
      build.group block
      if ret
        ret scope_name
    }

  foreach: (node) ->
    smart_node node
    if ntype(node.iter) == "unpack"
      list = node.iter[2]

      index_name = NameProxy "index"
      list_name = NameProxy "list"

      slice_var = nil
      bounds = if is_slice list
        slice = list[#list]
        table.remove list
        table.remove slice, 1

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

      build.group {
        build.assign_one list_name, list
        slice_var
        build["for"] {
          name: index_name
          bounds: bounds
          body: {
            {"assign", node.names, {list_name\index index_name}}
            build.group node.body
          }
        }
      }

  class: (node) ->
    _, name, parent_val, tbl = unpack node

    constructor = nil
    properties = for entry in *tbl[2]
      if entry[1] == constructor_name
        constructor = entry[2]
        nil
      else
        entry

    tbl[2] = properties

    parent_cls_name = NameProxy "parent"
    base_name = NameProxy "base"
    self_name = NameProxy "self"
    cls_name = NameProxy "class"

    if not constructor
      constructor = build.fndef {
        args: {{"..."}}
        arrow: "fat"
        body: {
          build["if"] {
            cond: parent_cls_name
            then: {
              build.chain { base: "super", {"call", {"..."}} }
            }
          }
        }
      }
    else
      smart_node constructor
      constructor.arrow = "fat"

    cls = build.table {
      {"__init", constructor}
    }

    cls_mt = build.table {
      {"__index", base_name}
      {"__call", build.fndef {
        args: {{"cls"}, {"..."}}
        body: {
          build.assign_one self_name, build.chain {
            base: "setmetatable"
            {"call", {"{}", base_name}}
          }
          build.chain {
            base: "cls.__init"
            {"call", {self_name, "..."}}
          }
          self_name
        }
      }}
    }

    cls = build.chain {
      base: "setmetatable"
      {"call", {cls, cls_mt}}
    }

    value = nil
    with build
      value = .block_exp {
        Run =>
          @set "super", (block, chain) ->
            calling_name = block\get"current_block"
            slice = [item for item in *chain[3,]]
            -- inject self
            slice[1] = {"call", {"self", unpack slice[1][2]}}

            act = if ntype(calling_name) != "value" then "index" else "dot"
            {"chain", parent_cls_name, {act, calling_name}, unpack slice}

        .assign_one parent_cls_name, parent_val == "" and "nil" or parent_val
        .assign_one base_name, tbl
        .assign_one base_name\chain"__index", base_name

        build["if"] {
          cond: parent_cls_name
          then: {
            .chain {
              base: "setmetatable"
              {"call", {base_name, .chain {
                base: "getmetatable"
                {"call", {parent_cls_name}}
                {"dot", "__index"}
              }}}
            }
          }
        }

        .assign_one cls_name, cls
        .assign_one base_name\chain"__class", cls_name

        cls_name
      }

      value = .group {
        .declare names: {name}
        .assign {
          names: {name}
          values: {value}
        }
      }

    value
}

class Accumulator
  body_idx: { for: 4, while: 3, foreach: 4 }

  new: =>
    @accum_name = NameProxy "accum"
    @value_name = NameProxy "value"
    @len_name = NameProxy "len"

  -- wraps node and mutates body
  convert: (node) =>
    index = @body_idx[ntype node]
    node[index] = @mutate_body node[index]
    @wrap node

  -- wrap the node into a block_exp
  wrap: (node) =>
    build.block_exp {
      build.assign_one @accum_name, build.table!
      build.assign_one @len_name, 0
      node
      @accum_name
    }

  -- mutates the body of a loop construct to save last value into accumulator
  -- can optionally skip nil results
  mutate_body: (body, skip_nil=true) =>
    val = if not skip_nil and is_singular body
      with body[1]
        body = {}
    else
      body = apply_to_last body, (n) ->
        build.assign_one @value_name, n
      @value_name

    update = {
      {"update", @len_name, "+=", 1}
      build.assign_one @accum_name\index(@len_name), val
    }

    if skip_nil
      table.insert body, build["if"] {
        cond: {"exp", @value_name, "!=", "nil"}
        then: update
      }
    else
      table.insert body, build.group update

    body

default_accumulator = (node) ->
  Accumulator!\convert node

implicitly_return = (stm) ->
  t = ntype stm
  if types.manual_return[t] or not is_value stm
    stm
  elseif types.cascading[t]
    Statement stm, implicitly_return
  else
    {"return", stm}

Value = Transformer {
  for: default_accumulator
  while: default_accumulator
  foreach: default_accumulator

  comprehension: (node) ->
    a = Accumulator!
    node = Statement node, (exp) ->
      a\mutate_body {exp}, false
    a\wrap node

  fndef: (node) ->
    smart_node node
    node.body = apply_to_last node.body, implicitly_return
    node

  if: (node) -> build.block_exp { node }
  with: (node) -> build.block_exp { node }

  -- pull out colon chain
  chain: (node) ->
    stub = node[#node]
    if type(stub) == "table" and stub[1] == "colon_stub"
      table.remove node, #node

      base_name = NameProxy "base"
      fn_name = NameProxy "fn"

      Value build.block_exp {
        build.assign {
          names: {base_name}
          values: {node}
        }

        build.assign {
          names: {fn_name}
          values: {
            build.chain { base: base_name, {"dot", stub[2]} }
          }
        }

        build.fndef {
          args: {{"..."}}
          body: {
            build.chain {
              base: fn_name, {"call", {base_name, "..."}}
            }
          }
        }
      }

  block_exp: (node) ->
    _, body = unpack node

    fn = nil
    arg_list = {}

    insert body, Run =>
      if @has_varargs
        insert arg_list, "..."
        insert fn.args, {"..."}

    fn = smart_node build.fndef body: body
    build.chain { base: {"parens", fn}, {"call", arg_list} }
}

