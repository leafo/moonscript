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
