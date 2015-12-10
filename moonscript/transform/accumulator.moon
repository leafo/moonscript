types = require "moonscript.types"

import build, ntype, NOOP from types
import NameProxy from require "moonscript.transform.names"

import insert from table

-- is a body a single expression/statement
is_singular = (body) ->
  return false if #body != 1
  if "group" == ntype body
    is_singular body[2]
  else
    body[1]

import transform_last_stm from require "moonscript.transform.statements"

class Accumulator
  body_idx: { for: 4, while: 3, foreach: 4 }

  new: (accum_name) =>
    @accum_name = NameProxy "accum"
    @value_name = NameProxy "value"
    @len_name = NameProxy "len"

  -- wraps node and mutates body
  convert: (node) =>
    index = @body_idx[ntype node]
    node[index] = @mutate_body node[index]
    @wrap node

  -- wrap the node into a block_exp
  wrap: (node, group_type="block_exp") =>
    build[group_type] {
      build.assign_one @accum_name, build.table!
      build.assign_one @len_name, 1
      node
      group_type == "block_exp" and @accum_name or NOOP
    }

  -- mutates the body of a loop construct to save last value into accumulator
  mutate_body: (body) =>
    -- shortcut to write simpler code if body is a single expression
    single_stm = is_singular body
    val = if single_stm and types.is_value single_stm
      body = {}
      single_stm
    else
      body = transform_last_stm body, (n) ->
        if types.is_value n
          build.assign_one @value_name, n
        else
          -- just ignore it
          build.group {
            {"declare", {@value_name}}
            n
          }
      @value_name

    update = {
      build.assign_one NameProxy.index(@accum_name, @len_name), val
      {"update", @len_name, "+=", 1}
    }

    insert body, build.group update
    body

default_accumulator = (node) =>
  Accumulator!\convert node

{ :Accumulator, :default_accumulator }
