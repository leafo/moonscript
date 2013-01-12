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
local k = (function()
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
local j = (function()
  local _accum_0 = { }
  local _len_0 = 1
  for i = 1, 10 do
    local _value_0
    _value_0 = function(...)
      return print(...)
    end
    if _value_0 ~= nil then
      _accum_0[_len_0] = _value_0
      _len_0 = _len_0 + 1
    end
  end
  return _accum_0
end)()
local m
m = function(...)
  return (function(...)
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
  end)(...)
end
local x = (function(...)
  local _accum_0 = { }
  local _len_0 = 1
  local _list_0 = {
    ...
  }
  for _index_0 = 1, #_list_0 do
    local i = _list_0[_index_0]
    local _value_0 = i
    if _value_0 ~= nil then
      _accum_0[_len_0] = _value_0
      _len_0 = _len_0 + 1
    end
  end
  return _accum_0
end)(...)
local y = (function(...)
  local _accum_0 = { }
  local _len_0 = 1
  local _list_0 = {
    ...
  }
  for _index_0 = 1, #_list_0 do
    x = _list_0[_index_0]
    _accum_0[_len_0] = x
    _len_0 = _len_0 + 1
  end
  return _accum_0
end)(...)
local z = (function(...)
  local _accum_0 = { }
  local _len_0 = 1
  for x in hallo do
    if f(...) > 4 then
      _accum_0[_len_0] = x
      _len_0 = _len_0 + 1
    end
  end
  return _accum_0
end)(...)
local a = (function(...)
  local _accum_0 = { }
  local _len_0 = 1
  for i = 1, 10 do
    local _value_0 = ...
    if _value_0 ~= nil then
      _accum_0[_len_0] = _value_0
      _len_0 = _len_0 + 1
    end
  end
  return _accum_0
end)(...)
local b = (function()
  local _accum_0 = { }
  local _len_0 = 1
  for i = 1, 10 do
    local _value_0
    _value_0 = function()
      return print(...)
    end
    if _value_0 ~= nil then
      _accum_0[_len_0] = _value_0
      _len_0 = _len_0 + 1
    end
  end
  return _accum_0
end)()