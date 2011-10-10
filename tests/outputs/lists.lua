local hi = (function()
  local _accum_0 = { }
  local _len_0 = 0
  for _, x in ipairs({
    1,
    2,
    3,
    4
  }) do
    _len_0 = _len_0 + 1
    _accum_0[_len_0] = x * 2
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
  local _len_0 = 0
  for self.x in ipairs(items) do
    _len_0 = _len_0 + 1
    _accum_0[_len_0] = self.x
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
  local _len_0 = 0
  for a in ipairs({
    1,
    2,
    3,
    4,
    5,
    6
  }) do
    if good_number(a) then
      _len_0 = _len_0 + 1
      _accum_0[_len_0] = {
        a
      }
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
  local _len_0 = 0
  for x in range(10) do
    _len_0 = _len_0 + 1
    _accum_0[_len_0] = x
  end
  return _accum_0
end)())
dump((function()
  local _accum_0 = { }
  local _len_0 = 0
  for x in range(5) do
    if x > 2 then
      for y in range(5) do
        _len_0 = _len_0 + 1
        _accum_0[_len_0] = {
          x,
          y
        }
      end
    end
  end
  return _accum_0
end)())
local things = (function()
  local _accum_0 = { }
  local _len_0 = 0
  for x in range(10) do
    if x > 5 then
      for y in range(10) do
        if y > 7 then
          _len_0 = _len_0 + 1
          _accum_0[_len_0] = x + y
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
  local _len_0 = 0
  for x in x do
    _len_0 = _len_0 + 1
    _accum_0[_len_0] = x
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
  local _len_0 = 0
  local _list_0 = items
  for _index_0 = 1, #_list_0 do
    x = _list_0[_index_0]
    _len_0 = _len_0 + 1
    _accum_0[_len_0] = x * 2
  end
  return _accum_0
end)()
local _list_0 = double
for _index_0 = 1, #_list_0 do
  x = _list_0[_index_0]
  print(x)
end
local cut = (function()
  local _accum_0 = { }
  local _len_0 = 0
  local _list_1 = items
  for _index_0 = 1, #_list_1 do
    x = _list_1[_index_0]
    if x > 3 then
      _len_0 = _len_0 + 1
      _accum_0[_len_0] = x
    end
  end
  return _accum_0
end)()
local hello = (function()
  local _accum_0 = { }
  local _len_0 = 0
  local _list_1 = items
  for _index_0 = 1, #_list_1 do
    x = _list_1[_index_0]
    local _list_2 = items
    for _index_0 = 1, #_list_2 do
      local y = _list_2[_index_0]
      _len_0 = _len_0 + 1
      _accum_0[_len_0] = x + y
    end
  end
  return _accum_0
end)()
local _list_1 = hello
for _index_0 = 1, #_list_1 do
  local z = _list_1[_index_0]
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
local _list_2 = x
local _max_0 = -5
for _index_0 = 2, _max_0 < 0 and #_list_2 + _max_0 or _max_0, 2 do
  local y = _list_2[_index_0]
  print(y)
end
local _list_3 = x
local _max_1 = 3
for _index_0 = 1, _max_1 < 0 and #_list_3 + _max_1 or _max_1 do
  local y = _list_3[_index_0]
  print(y)
end
local _list_4 = x
for _index_0 = 2, #_list_4 do
  local y = _list_4[_index_0]
  print(y)
end
local _list_5 = x
for _index_0 = 1, #_list_5, 2 do
  local y = _list_5[_index_0]
  print(y)
end
local _list_6 = x
for _index_0 = 2, #_list_6, 2 do
  local y = _list_6[_index_0]
  print(y)
end
local f
f = function(...)
  return #{
    ...
  }
end
x = function(...)
  return (function()
    local _accum_0 = { }
    local _len_0 = 0
    local _list_7 = {
      ...
    }
    for _index_0 = 1, #_list_7 do
      x = _list_7[_index_0]
      if f(...) > 4 then
        _len_0 = _len_0 + 1
        _accum_0[_len_0] = x * x
      end
    end
    return _accum_0
  end)()
end
local normal
normal = function(hello)
  return (function()
    local _accum_0 = { }
    local _len_0 = 0
    for x in yeah do
      _len_0 = _len_0 + 1
      _accum_0[_len_0] = x
    end
    return _accum_0
  end)()
end
local dont_bubble
dont_bubble = function()
  return (function()
    local _accum_0 = { }
    local _len_0 = 0
    for x in (function(...)
      return print(...)
    end)("hello") do
      _len_0 = _len_0 + 1
      _accum_0[_len_0] = x
    end
    return _accum_0
  end)()
end
local test = x(1, 2, 3, 4, 5)
local _list_7 = test
for _index_0 = 1, #_list_7 do
  local thing = _list_7[_index_0]
  print(thing)
end