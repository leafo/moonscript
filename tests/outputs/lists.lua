local hi = (function()
  local _moon_0 = {}
  for _, x in ipairs({
      1,
      2,
      3,
      4
    }) do
    table.insert(_moon_0, x * 2)
  end
  return _moon_0
end)()
local items = {
  1,
  2,
  3,
  4,
  5,
  6
}
local mm = (function()
  local _moon_0 = {}
  for self.x in ipairs(items) do
    table.insert(_moon_0, self.x)
  end
  return _moon_0
end)()
for z in ipairs(items) do
  if z > 4 then
    local _ = z
  end
end
local rad = (function()
  local _moon_0 = {}
  for a in ipairs({
      1,
      2,
      3,
      4,
      5,
      6
    }) do
    if good_number(a) then
      table.insert(_moon_0, { a })
    end
  end
  return _moon_0
end)()
for z in items do
  for j in list do
    if z > 4 then
      local _ = z
    end
  end
end
require("util")
local dump
dump = function(x) return print(util.dump(x)) end
local range
range = function(count)
  local i = 0
  return coroutine.wrap(function()
    while i < count do
      coroutine.yield(i)
      i = i + 1
    end
  end)
end
dump((function()
  local _moon_0 = {}
  for x in range(10) do
    table.insert(_moon_0, x)
  end
  return _moon_0
end)())
dump((function()
  local _moon_0 = {}
  for x in range(5) do
    if x > 2 then
      for y in range(5) do
        table.insert(_moon_0, { x, y })
      end
    end
  end
  return _moon_0
end)())
local things = (function()
  local _moon_0 = {}
  for x in range(10) do
    if x > 5 then
      for y in range(10) do
        if y > 7 then
          table.insert(_moon_0, x + y)
        end
      end
    end
  end
  return _moon_0
end)()
for x in ipairs({ 1, 2, 4 }) do
  for y in ipairs({ 1, 2, 3 }) do
    if x ~= 2 then
      print(x, y)
    end
  end
end
for x in items do
  print("hello", x)
end
for x in x do
  local _ = x
end
local x = (function()
  local _moon_0 = {}
  for x in x do
    table.insert(_moon_0, x)
  end
  return _moon_0
end)()
for x in ipairs({ 1, 2, 4 }) do
  for y in ipairs({ 1, 2, 3 }) do
    if x ~= 2 then
      print(x, y)
    end
  end
end
local double = (function()
  local _moon_0 = {}
  local _item_0 = items
  for _index_0=1,#_item_0 do
    local x = _item_0[_index_0]
    table.insert(_moon_0, x * 2)
  end
  return _moon_0
end)()
local _item_0 = double
for _index_0=1,#_item_0 do
  local x = _item_0[_index_0]
  print(x)
end
local cut = (function()
  local _moon_0 = {}
  local _item_0 = items
  for _index_0=1,#_item_0 do
    local x = _item_0[_index_0]
    if x > 3 then
      table.insert(_moon_0, x)
    end
  end
  return _moon_0
end)()
local hello = (function()
  local _moon_0 = {}
  local _item_1 = items
  for _index_1=1,#_item_1 do
    local x = _item_1[_index_1]
    local _item_0 = items
    for _index_0=1,#_item_0 do
      local y = _item_0[_index_0]
      table.insert(_moon_0, x + y)
    end
  end
  return _moon_0
end)()
local _item_0 = hello
for _index_0=1,#_item_0 do
  local z = _item_0[_index_0]
  print(z)
end