
module "moonscript.transform", package.seeall

types = require "moonscript.types"
util = require "moonscript.util"
data = require "moonscript.data"

import ntype, build, smart_node, is_slice from types
import insert from table

export stm, value, NameProxy, Run

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
apply_to_last = (stms, fn using nil) ->
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

constructor_name = "new"

Transformer = (transformers) ->
  seen_nodes = {}
  (n) ->
    return n if seen_nodes[n]
    seen_nodes[n] = true
    while true
      transformer = transformers[ntype n]
      res = if transformer
        transformer(n) or n
      else
        n
      return n if res == n
      n = res

stm = Transformer {
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

  class: (node using nil) ->
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
            slice = [item for item in *chain[3:]]
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

create_accumulator = (body_index) ->
  (node) ->
    accum_name = NameProxy "accum"
    value_name = NameProxy "value"
    len_name = NameProxy "len"

    body = apply_to_last node[body_index], (n) ->
      build.assign_one value_name, n

    table.insert body, build["if"] {
      cond: {"exp", value_name, "!=", "nil"}
      then: {
        {"update", len_name, "+=", 1}
        build.assign_one accum_name\index(len_name), value_name
      }
    }

    node[body_index] = body

    build.block_exp {
      build.assign_one accum_name, build.table!
      build.assign_one len_name, 0
      node
      accum_name
    }

value = Transformer {
  for: create_accumulator 4
  while: create_accumulator 3
  foreach: create_accumulator 4

  -- pull out colon chain
  chain: (node) ->
    stub = node[#node]
    if type(stub) == "table" and stub[1] == "colon_stub"
      table.remove node, #node

      base_name = NameProxy "base"
      fn_name = NameProxy "fn"

      value build.block_exp {
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

