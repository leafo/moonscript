local A
do
  local _class_0
  local _base_0 = {
    inc = function(self, val)
      if val == nil then
        val = 1
      end
      return self.__class(self.v + val)
    end,
    dec = function(self, val)
      if val == nil then
        val = 1
      end
      return self.__class(self.v - val)
    end,
    val = function(self)
      return self.v
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, v)
      if v == nil then
        v = 0
      end
      self.v = v
    end,
    __base = _base_0,
    __name = "A"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  A = _class_0
end
local a = A()
a = a:inc(2)
assert(a.v == 2)
a = a:inc()
assert(a.v == 3)
a = a:dec()
assert(a.v == 2)
a = a:val()
return assert(a == 2)