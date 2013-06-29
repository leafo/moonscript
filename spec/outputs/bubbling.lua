local f
f = function(...)
  return #{
    ...
  }
end
local dont_bubble
dont_bubble = function()
  return (function()
    local _accum_0 = { }
    local _len_0 = 1
    for x in (function(...)
      return print(...)
    end)("hello") do
      _accum_0[_len_0] = x
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)()
end
local k = { }
local _len_0 = 1
for x in (function(...)
  return print(...)
end)("hello") do
  k[_len_0] = x
  _len_0 = _len_0 + 1
end
local j = (function()
  local _accum_0 = { }
  local _len_1 = 1
  for i = 1, 10 do
    _accum_0[_len_1] = function(...)
      return print(...)
    end
    _len_1 = _len_1 + 1
  end
  return _accum_0
end)()
local m
m = function(...)
  return (function(...)
    local _list_0 = {
      ...
    }
    local _accum_0 = { }
    local _len_1 = 1
    for _index_0 = 1, #_list_0 do
      local x = _list_0[_index_0]
      if f(...) > 4 then
        _accum_0[_len_1] = x
        _len_1 = _len_1 + 1
      end
    end
    return _accum_0
  end)(...)
end
local x = (function(...)
  local _accum_0 = { }
  local _len_1 = 1
  local _list_0 = {
    ...
  }
  for _index_0 = 1, #_list_0 do
    local i = _list_0[_index_0]
    _accum_0[_len_1] = i
    _len_1 = _len_1 + 1
  end
  return _accum_0
end)(...)
local _list_0 = {
  ...
}
local y = { }
local _len_1 = 1
for _index_0 = 1, #_list_0 do
  x = _list_0[_index_0]
  y[_len_1] = x
  _len_1 = _len_1 + 1
end
local z = { }
local _len_2 = 1
for x in hallo do
  if f(...) > 4 then
    z[_len_2] = x
    _len_2 = _len_2 + 1
  end
end
local a = (function(...)
  local _accum_0 = { }
  local _len_3 = 1
  for i = 1, 10 do
    _accum_0[_len_3] = ...
    _len_3 = _len_3 + 1
  end
  return _accum_0
end)(...)
local b = (function()
  local _accum_0 = { }
  local _len_3 = 1
  for i = 1, 10 do
    _accum_0[_len_3] = function()
      return print(...)
    end
    _len_3 = _len_3 + 1
  end
  return _accum_0
end)()