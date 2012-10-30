a, b, c = 223, 343
cool = "dad"
Something = (function()
  local _parent_0 = nil
  local _base_0 = {
    umm = "cool"
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self, ...)
      if _parent_0 then
        return _parent_0.__init(self, ...)
      end
    end,
    __base = _base_0,
    __name = "Something",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil and _parent_0 then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0 and _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  return _class_0
end)()
local What
if this then
  What = 232
else
  What = 4343
end
local d
a, b, c, d = "hello"
local another = 3434
Another = 7890
if inner then
  local Yeah = "10000"
end
if this then
  What = 232
else
  What = 4343
end
if this then
  What = 232
else
  What = 4343
end
x, y, z = 1, 2, 3
y = function()
  local hallo = 3434
end
do
  local _with_0 = tmp
  local j = 2000
  return _with_0
end