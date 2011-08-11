module("moonscript.compile", package.seeall)
local util = require("moonscript.util")
local data = require("moonscript.data")
local ntype = data.ntype
local key_table = {
  fndef = {
    "args",
    "whitelist",
    "arrow",
    "body"
  }
}
local build_table
build_table = function()
  for key, value in pairs(key_table) do
    local index = { }
    for i, name in ipairs(value) do
      index[name] = i + 1
    end
    key_table[key] = index
  end
end
build_table()
smart_node = function(node)
  local index = key_table[ntype(node)]
  if not index then
    return node
  end
  return setmetatable(node, {
    __index = function(node, key)
      if index[key] then
        return rawget(node, index[key])
      elseif type(key) == "string" then
        return error("unknown key: `" .. key .. "` on node type: `" .. ntype(node) .. "`")
      end
    end,
    __newindex = function(node, key, value)
      if index[key] then
        key = index[key]
      end
      return rawset(node, key, value)
    end
  })
end
