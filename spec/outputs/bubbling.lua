local f
f = function(...)
  return #{
    ...
  }
end
local dont_bubble
dont_bubble = function()
  local _accum_0 = { }
  local _len_0 = 1
  for x in (function(...)
    return print(...)
  end)("hello") do
    _accum_0[_len_0] = x
    _len_0 = _len_0 + 1
  end
  return _accum_0
end
local k
do
  local _accum_0 = { }
  local _len_0 = 1
  for x in (function(...)
    return print(...)
  end)("hello") do
    _accum_0[_len_0] = x
    _len_0 = _len_0 + 1
  end
  k = _accum_0
end
local j
do
  local _accum_0 = { }
  local _len_0 = 1
  for i = 1, 10 do
    _accum_0[_len_0] = function(...)
      return print(...)
    end
    _len_0 = _len_0 + 1
  end
  j = _accum_0
end
local m
m = function(...)
  local _accum_0 = { }
  local _len_0 = 1
  local _list_0 = {
    ...
  }
  for _index_0 = 1, #_list_0 do
    local x = _list_0[_index_0]
    if f(...) > 4 then
      _accum_0[_len_0] = x
      _len_0 = _len_0 + 1
    end
  end
  return _accum_0
end
local x
do
  local _accum_0 = { }
  local _len_0 = 1
  local _list_0 = {
    ...
  }
  for _index_0 = 1, #_list_0 do
    local i = _list_0[_index_0]
    _accum_0[_len_0] = i
    _len_0 = _len_0 + 1
  end
  x = _accum_0
end
local y
do
  local _accum_0 = { }
  local _len_0 = 1
  local _list_0 = {
    ...
  }
  for _index_0 = 1, #_list_0 do
    local x = _list_0[_index_0]
    _accum_0[_len_0] = x
    _len_0 = _len_0 + 1
  end
  y = _accum_0
end
local z
do
  local _accum_0 = { }
  local _len_0 = 1
  for x in hallo do
    if f(...) > 4 then
      _accum_0[_len_0] = x
      _len_0 = _len_0 + 1
    end
  end
  z = _accum_0
end
local a
do
  local _accum_0 = { }
  local _len_0 = 1
  for i = 1, 10 do
    _accum_0[_len_0] = ...
    _len_0 = _len_0 + 1
  end
  a = _accum_0
end
local b
do
  local _accum_0 = { }
  local _len_0 = 1
  for i = 1, 10 do
    _accum_0[_len_0] = function()
      return print(...)
    end
    _len_0 = _len_0 + 1
  end
  b = _accum_0
end