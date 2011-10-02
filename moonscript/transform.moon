
module "moonscript.transform", package.seeall

types = require "moonscript.types"
util = require "moonscript.util"
data = require "moonscript.data"

import ntype, build, smart_node from types
import insert from table

export node, NameProxy

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

constructor_name = "new"

transformers = {
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

  -- pull out colon chain
  chain: (node) ->
    stub = node[#node]
    if type(stub) == "table" and stub[1] == "colon_stub"
      table.remove node, #node

      base_name = NameProxy "base"
      fn_name = NameProxy "fn"

      build.block_exp {
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
}

node = (n) ->
  transformer = transformers[ntype n]
  if transformer
    transformer(n) or n
  else
    n


