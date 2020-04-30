do
  local a
  local a, b, c
  local g
  b, g = 23232
end
do
  local x = 1212
  local something
  something = function()
    local x
    x = 1212
  end
end
do
  local y, z
  y = 2323
  z = 2323
end
do
  print("Nothing Here!")
end
do
  local X, Y
  local x = 3434
  local y = 3434
  X = 3434
  Y = "yeah"
end
do
  local x, y = "a", "b"
end
do
  local x, y
  x, y = "a", "b"
end
do
  if something then
    local x = 2323
  end
end
do
  local x
  do
    x = "one"
  end
  x = 100
  do
    x = "two"
  end
end
do
  local k, x, a, b, c
  if what then
    k = 10
  end
  x = 100
  do
    local _obj_0 = y
    a, b, c = _obj_0.a, _obj_0.b, _obj_0.c
  end
end
do
  local a, b, c, d
  a = 100
  print("hi")
  b = 200
  c = 100
  print("hi")
  d = 200
  d = 2323
end
do
  local Uppercase, One, Two
  local lowercase = 5
  Uppercase = 3
  do
    local _class_0
    local Five
    local _base_0 = { }
    _base_0.__index = _base_0
    _class_0 = setmetatable({
      __init = function() end,
      __base = _base_0,
      __name = "One"
    }, {
      __index = _base_0,
      __call = function(cls, ...)
        local _self_0 = setmetatable({}, _base_0)
        cls.__init(_self_0, ...)
        return _self_0
      end
    })
    _base_0.__class = _class_0
    local self = _class_0
    Five = 6
    One = _class_0
  end
  do
    local _class_0
    local No
    local _base_0 = { }
    _base_0.__index = _base_0
    _class_0 = setmetatable({
      __init = function() end,
      __base = _base_0,
      __name = "Two"
    }, {
      __index = _base_0,
      __call = function(cls, ...)
        local _self_0 = setmetatable({}, _base_0)
        cls.__init(_self_0, ...)
        return _self_0
      end
    })
    _base_0.__class = _class_0
    local self = _class_0
    do
      local _class_1
      local _base_1 = { }
      _base_1.__index = _base_1
      _class_1 = setmetatable({
        __init = function() end,
        __base = _base_1,
        __name = "No"
      }, {
        __index = _base_1,
        __call = function(cls, ...)
          local _self_0 = setmetatable({}, _base_1)
          cls.__init(_self_0, ...)
          return _self_0
        end
      })
      _base_1.__class = _class_1
      No = _class_1
    end
    Two = _class_0
  end
end
do
  local _list_0 = { }
  for _index_0 = 1, #_list_0 do
    local a = _list_0[_index_0]
    local _ = a
  end
end
local g = 2323
