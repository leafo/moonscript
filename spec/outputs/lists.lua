local hi = (function()
  local _accum_0 = { }
  local _len_0 = 1
  for _, x in ipairs({
    1,
    2,
    3,
    4
  }) do
    _accum_0[_len_0] = x * 2
    _len_0 = _len_0 + 1
  end
  return _accum_0
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
  local _accum_0 = { }
  local _len_0 = 1
  for self.x in ipairs(items) do
    _accum_0[_len_0] = self.x
    _len_0 = _len_0 + 1
  end
  return _accum_0
end)()
for z in ipairs(items) do
  if z > 4 then
    local _ = z
  end
end
local rad = (function()
  local _accum_0 = { }
  local _len_0 = 1
  for a in ipairs({
    1,
    2,
    3,
    4,
    5,
    6
  }) do
    if good_number(a) then
      _accum_0[_len_0] = {
        a
      }
      _len_0 = _len_0 + 1
    end
  end
  return _accum_0
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
dump = function(x)
  return print(util.dump(x))
end
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
  local _accum_0 = { }
  local _len_0 = 1
  for x in range(10) do
    _accum_0[_len_0] = x
    _len_0 = _len_0 + 1
  end
  return _accum_0
end)())
dump((function()
  local _accum_0 = { }
  local _len_0 = 1
  for x in range(5) do
    if x > 2 then
      for y in range(5) do
        _accum_0[_len_0] = {
          x,
          y
        }
        _len_0 = _len_0 + 1
      end
    end
  end
  return _accum_0
end)())
local things = (function()
  local _accum_0 = { }
  local _len_0 = 1
  for x in range(10) do
    if x > 5 then
      for y in range(10) do
        if y > 7 then
          _accum_0[_len_0] = x + y
          _len_0 = _len_0 + 1
        end
      end
    end
  end
  return _accum_0
end)()
for x in ipairs({
  1,
  2,
  4
}) do
  for y in ipairs({
    1,
    2,
    3
  }) do
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
  local _accum_0 = { }
  local _len_0 = 1
  for x in x do
    _accum_0[_len_0] = x
    _len_0 = _len_0 + 1
  end
  return _accum_0
end)()
for x in ipairs({
  1,
  2,
  4
}) do
  for y in ipairs({
    1,
    2,
    3
  }) do
    if x ~= 2 then
      print(x, y)
    end
  end
end
local double = (function()
  local _accum_0 = { }
  local _len_0 = 1
  for _index_0 = 1, #items do
    x = items[_index_0]
    _accum_0[_len_0] = x * 2
    _len_0 = _len_0 + 1
  end
  return _accum_0
end)()
for _index_0 = 1, #double do
  x = double[_index_0]
  print(x)
end
local cut = (function()
  local _accum_0 = { }
  local _len_0 = 1
  for _index_0 = 1, #items do
    x = items[_index_0]
    if x > 3 then
      _accum_0[_len_0] = x
      _len_0 = _len_0 + 1
    end
  end
  return _accum_0
end)()
local hello = (function()
  local _accum_0 = { }
  local _len_0 = 1
  for _index_0 = 1, #items do
    x = items[_index_0]
    for _index_1 = 1, #items do
      local y = items[_index_1]
      _accum_0[_len_0] = x + y
      _len_0 = _len_0 + 1
    end
  end
  return _accum_0
end)()
for _index_0 = 1, #hello do
  local z = hello[_index_0]
  print(z)
end
x = {
  1,
  2,
  3,
  4,
  5,
  6,
  7
}
local _list_0 = x
local _max_0 = -5
for _index_0 = 2, _max_0 < 0 and #_list_0 + _max_0 or _max_0, 2 do
  local y = _list_0[_index_0]
  print(y)
end
local _list_1 = x
local _max_1 = 3
for _index_0 = 1, _max_1 < 0 and #_list_1 + _max_1 or _max_1 do
  local y = _list_1[_index_0]
  print(y)
end
local _list_2 = x
for _index_0 = 2, #_list_2 do
  local y = _list_2[_index_0]
  print(y)
end
local _list_3 = x
for _index_0 = 1, #_list_3, 2 do
  local y = _list_3[_index_0]
  print(y)
end
local _list_4 = x
for _index_0 = 2, #_list_4, 2 do
  local y = _list_4[_index_0]
  print(y)
end
local a, b, c = 1, 5, 2
local _list_5 = x
local _max_2 = b
for _index_0 = a, _max_2 < 0 and #_list_5 + _max_2 or _max_2, c do
  local y = _list_5[_index_0]
  print(y)
end
local normal
normal = function(hello)
  return (function()
    local _accum_0 = { }
    local _len_0 = 1
    for x in yeah do
      _accum_0[_len_0] = x
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)()
end
local test = x(1, 2, 3, 4, 5)
for _index_0 = 1, #test do
  local thing = test[_index_0]
  print(thing)
end
local _
_ = function()
  local _list_6 = rows
  for _index_0 = 1, #_list_6 do
    local row = _list_6[_index_0]
    a = b
  end
end
_ = function()
  for _index_0 = 1, #things do
    x = things[_index_0]
    _ = x
  end
end
return function()
  return (function()
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #things do
      x = things[_index_0]
      _accum_0[_len_0] = x
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)()
end