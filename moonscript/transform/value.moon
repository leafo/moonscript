import Transformer from require "moonscript.transform.transformer"
import build, ntype, smart_node from require "moonscript.types"

import NameProxy from require "moonscript.transform.names"
import Accumulator, default_accumulator from require "moonscript.transform.accumulator"
import lua_keywords from require "moonscript.data"

import Run, transform_last_stm, implicitly_return, chain_is_stub from require "moonscript.transform.statements"

import construct_comprehension from require "moonscript.transform.comprehension"

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
    node.body = {
      Run => @listen "varargs", -> -- capture event
      unpack node.body
    }

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

    fn = nil
    arg_list = {}

    fn = smart_node build.fndef body: {
      Run =>
        @listen "varargs", ->
          insert arg_list, "..."
          insert fn.args, {"..."}
          @unlisten "varargs"

      unpack body
    }

    build.chain { base: {"parens", fn}, {"call", arg_list} }
}

