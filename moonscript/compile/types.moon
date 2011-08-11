module "moonscript.compile", package.seeall

util = require "moonscript.util"
data = require "moonscript.data"

import ntype from data
export smart_node

-- todo: this should be merged into data
-- lets us index a node by item name based on it's type

key_table = {
  fndef: {"args", "whitelist", "arrow", "body"}
}

build_table =  ->
  for key, value in pairs key_table
    index = {}
    index[name] = i + 1 for i, name in ipairs value
    key_table[key] = index

build_table!

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
    
