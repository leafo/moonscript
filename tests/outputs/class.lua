local Hello = (function()
  local _base_0 = { hello = function(self) return print(self.test, self.world) end, __tostring = function(self) return "hello world" end }
  _base_0.__index = _base_0
  return setmetatable({ __init = function(self, test, world)
      self.test, self.world = test, world
      return print("creating object..")
    end }, { __index = _base_0, __call = function(mt, ...)
      local self = setmetatable({}, _base_0)
      mt.__init(self, ...)
      return self
    end })
end)()
local x = Hello(1, 2)
x:hello()
print(x)