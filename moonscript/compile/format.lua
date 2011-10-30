module("moonscript.compile", package.seeall)
local util = require("moonscript.util")
local data = require("moonscript.data")
local Set
do
  local _table_0 = require("moonscript.data")
  Set = _table_0.Set
end
local ntype
do
  local _table_0 = require("moonscript.types")
  ntype = _table_0.ntype
end
local concat, insert = table.concat, table.insert
indent_char = "  "
user_error = function(...)
  return error({
    "user-error",
    ...
  })
end
local manual_return = Set({
  "foreach",
  "for",
  "while"
})
default_return = function(exp)
  local t = ntype(exp)
  if t == "chain" and exp[2] == "return" then
    local items = {
      "explist"
    }
    local _list_0 = exp[3][2]
    for _index_0 = 1, #_list_0 do
      local v = _list_0[_index_0]
      insert(items, v)
    end
    return {
      "return",
      items
    }
  elseif manual_return[t] then
    return exp
  else
    return {
      "return",
      exp
    }
  end
end
moonlib = {
  bind = function(tbl, name)
    return concat({
      "moon.bind(",
      tbl,
      ".",
      name,
      ", ",
      tbl,
      ")"
    })
  end
}
cascading = Set({
  "if",
  "with"
})
non_atomic = Set({
  "update"
})
has_value = function(node)
  if ntype(node) == "chain" then
    local ctype = ntype(node[#node])
    return ctype ~= "call" and ctype ~= "colon"
  else
    return true
  end
end
is_non_atomic = function(node)
  return non_atomic[ntype(node)]
end
count_lines = function(str)
  local count = 1
  for _ in str:gmatch("\n") do
    count = count + 1
  end
  return count
end
