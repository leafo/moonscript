local hello = yeah.hello
local hello, world
do
  local _table_0 = table["cool"]
  hello, world = _table_0.hello, _table_0.world
end
local a, b, c = items.a, (function()
  local _base_0 = items
  local _fn_0 = _base_0.b
  return function(...)
    return _fn_0(_base_0, ...)
  end
end)(), items.c
local master, ghost
do
  local _table_0 = find("mytable")
  master, ghost = _table_0.master, (function()
    local _base_0 = _table_0
    local _fn_0 = _base_0.ghost
    return function(...)
      return _fn_0(_base_0, ...)
    end
  end)()
end
local yumm
a, yumm = 3434, "hello"
local _table_0 = 232
local something
do
  local _table_1 = a(table)
  something = _table_1.something
end
if indent then
  local okay, well
  do
    local _table_1 = tables[100]
    okay, well = _table_1.okay, (function()
      local _base_0 = _table_1
      local _fn_0 = _base_0.well
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)()
  end
end