module("moonscript.compile", package.seeall)
local util = require("moonscript.util")
local data = require("moonscript.data")
local itwos = util.itwos
local Set, ntype = data.Set, data.ntype
local concat, insert = table.concat, table.insert
indent_char = "  "
pretty = function(lines, indent)
  indent = indent or ""
  local render
  render = function(line)
    if type(line) == "table" then
      return indent_char .. pretty(line, indent .. indent_char)
    else
      return line
    end
  end
  lines = (function()
    local _moon_0 = {}
    local _item_0 = lines
    for _index_0=1,#_item_0 do
      local line = _item_0[_index_0]
      table.insert(_moon_0, render(line))
    end
    return _moon_0
  end)()
  local fix
  fix = function(i, left, k, right)
    if left:sub(-1) == ")" and right:sub(1, 1) == "(" then
      lines[i] = lines[i] .. ";"
    end
  end
  for i, l, k, r in itwos(lines) do
    fix(i, l, k, r)
  end
  return indent .. concat(lines, "\n" .. indent)
end
returner = function(exp)
  if ntype(exp) == "chain" and exp[2] == "return" then
    local items = { "explist" }
    local _item_0 = exp[3][2]
    for _index_0=1,#_item_0 do
      local v = _item_0[_index_0]
      insert(items, v)
    end
    return { "return", items }
  else
    return { "return", exp }
  end
end
moonlib = { bind = function(tbl, name) return concat({
      "moon.bind(",
      tbl,
      ".",
      name,
      ", ",
      tbl,
      ")"
    }) end }
cascading = Set({ "if", "with" })
non_atomic = Set({ "update" })
has_value = function(node)
  if ntype(node) == "chain" then
    local ctype = ntype(node[#node])
    return ctype ~= "call" and ctype ~= "colon"
  else
    return true
  end
end
is_non_atomic = function(node) return non_atomic[ntype(node)] end
count_lines = function(str)
  local count = 1
  for _ in str:gmatch("\n") do
    count = count + 1
  end
  return count
end
