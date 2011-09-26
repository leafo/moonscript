module "moonscript.compile", package.seeall

util = require "moonscript.util"
data = require "moonscript.data"

import ntype from data
export smart_node, build

-- todo: this should be merged into data
-- lets us index a node by item name based on it's type

t = {}

node_types = {
  fndef: {
    {"args", t}
    {"whitelist", t}
    {"arrow", "slim"}
    {"body", t}
  }
}

build_table =  ->
  key_table = {}
  for name, args in pairs node_types
    index = {}
    for i, tuple in ipairs args
      name = tuple[1]
      index[name] = i + 1
    key_table[name] = index
  key_table

key_table = build_table!


make_builder = (name) ->
  spec = node_types[name]
  error "don't know how to build node: "..name if not spec
  (props={}) ->
    node = { name }
    for i, arg in ipairs spec
      name, default_value = unpack arg
      val = if props[name] then props[name] else default_value
      val = {} if val == t
      node[i + 1] = val
    node

build = setmetatable {}, {
  __index: (name) =>
    self[name] = make_builder name
    rawget self, name
}

smart_node = (node) ->
  index = key_table[ntype node]
  if not index then return node
  setmetatable node, {
    __index: (node, key) ->
      if index[key]
        rawget node, index[key]
      elseif type(key) == "string"
        error "unknown key: `"..key.."` on node type: `"..ntype(node).. "`"

    __newindex: (node, key, value) ->
      key = index[key] if index[key]
      rawset node, key, value
  }
    
