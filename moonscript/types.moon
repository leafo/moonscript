module "moonscript.types", package.seeall
util = require "moonscript.util"
data = require "moonscript.data"

export ntype, smart_node, build
import insert from table


-- type of node as string
ntype = (node) ->
  if type(node) != "table"
    "value"
  else
    node[1]

t = {}

node_types = {
  fndef: {
    {"args", t}
    {"whitelist", t}
    {"arrow", "slim"}
    {"body", t}
  }
  assign: {
    {"names", t}
    {"values", t}
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
      key, default_value = unpack arg
      val = if props[key] then props[key] else default_value
      val = {} if val == t
      node[i + 1] = val
    node

build = nil
build = setmetatable {
  block_exp: (body) ->
    fn = build.fndef body: body
    build.chain { base: {"parens", fn}, {"call", {}} }
  chain: (parts) ->
    base = parts.base or error"expecting base property for chain"
    node = {"chain", base}
    for part in *parts
      insert node, part
    node
}, {
  __index: (name) =>
    self[name] = make_builder name
    rawget self, name
}

-- makes it so node properties can be accessed by name instead of index
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
    
