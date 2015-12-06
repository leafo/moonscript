
util = require "moonscript.util"
import Set from require "moonscript.data"

import insert from table
import unpack from util

-- implicit return does not work on these statements
manual_return = Set {
  "foreach", "for", "while", "return"
}

-- Assigns and returns are bubbled into their bodies.
-- All cascading statement transform functions accept a second arugment that
-- is the transformation to apply to the last statement in their body
cascading = Set {
  "if", "unless", "with", "switch", "class", "do"
}

terminating = Set {
  "return", "break"
}

-- type of node as string
ntype = (node) ->
  switch type node
    when "nil"
      "nil"
    when "table"
      node[1]
    else
      "value"

-- gets the class of a type if possible
mtype = do
  moon_type = util.moon.type
  -- lets us check a smart node without throwing an error
  (val) ->
    mt = getmetatable val
    return "table" if mt and mt.smart_node
    moon_type val

-- can this value be compiled in a line by itself
value_can_be_statement = (node) ->
  return false unless ntype(node) == "chain"
  -- it's a function call
  ntype(node[#node]) == "call"

is_value = (stm) ->
  compile = require "moonscript.compile"
  transform = require "moonscript.transform"

  compile.Block\is_value(stm) or transform.Value\can_transform stm

value_is_singular = (node) ->
  type(node) != "table" or node[1] != "exp" or #node == 2

is_slice = (node) ->
  ntype(node) == "chain" and ntype(node[#node]) == "slice"

t = {}
node_types = {
  class: {
    {"name", "Tmp"}
    {"body", t}
  }
  fndef: {
    {"args", t}
    {"whitelist", t}
    {"arrow", "slim"}
    {"body", t}
  }
  foreach: {
    {"names", t}
    {"iter"}
    {"body", t}
  }
  for: {
    {"name"}
    {"bounds", t}
    {"body", t}
  }
  while: {
    {"cond", t}
    {"body", t}
  }
  assign: {
    {"names", t}
    {"values", t}
  }
  declare: {
    {"names", t}
  }
  if: {
    {"cond", t}
    {"then", t}
  }
}

build_table =  ->
  key_table = {}
  for node_name, args in pairs node_types
    index = {}
    for i, tuple in ipairs args
      prop_name = tuple[1]
      index[prop_name] = i + 1
    key_table[node_name] = index
  key_table

key_table = build_table!


make_builder = (name) ->
  spec = node_types[name]
  error "don't know how to build node: "..name if not spec
  (props={}) ->
    node = { name }
    for i, arg in ipairs spec
      key, default_value = unpack arg
      val = if props[key] then props[key] else default_value
      val = {} if val == t
      node[i + 1] = val
    node

build = nil
build = setmetatable {
  group: (body={}) ->
    {"group", body}

  do: (body) ->
    {"do", body}

  assign_one: (name, value) ->
    build.assign {
      names: {name}
      values: {value}
    }

  table: (tbl={}) ->
    -- convert strings to key literals
    for tuple in *tbl
      if type(tuple[1]) == "string"
        tuple[1] = {"key_literal", tuple[1]}

    {"table", tbl}
  block_exp: (body) ->
    {"block_exp", body}

  chain: (parts) ->
    base = parts.base or error"expecting base property for chain"

    if type(base) == "string"
      base = {"ref", base}

    node = {"chain", base}
    for part in *parts
      insert node, part
    node
}, {
  __index: (name) =>
    self[name] = make_builder name
    rawget self, name
}

smart_node_mt = setmetatable {}, {
  __index: (node_type) =>
    index = key_table[node_type]
    mt = {
      smart_node: true

      __index: (node, key) ->
        if index[key]
          rawget node, index[key]
        elseif type(key) == "string"
          error "unknown key: `"..key.."` on node type: `"..ntype(node).. "`"

      __newindex: (node, key, value) ->
        key = index[key] if index[key]
        rawset node, key, value
    }
    self[node_type] = mt
    mt
}

-- makes it so node properties can be accessed by name instead of index
smart_node = (node) ->
  setmetatable node, smart_node_mt[ntype node]

NOOP = {"noop"}

{
  :ntype, :smart_node, :build, :is_value, :is_slice, :manual_return,
  :cascading, :value_is_singular,
  :value_can_be_statement, :mtype, :terminating
  :NOOP
}

