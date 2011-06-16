local Hello = (function(_parent_0)
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
local Simple = (function(_parent_0)
  local _base_0 = { cool = function(self) return print("cool") end }
  _base_0.__index = _base_0
  return setmetatable({ __init = function(self) end }, { __index = _base_0, __call = function(mt, ...)
      local self = setmetatable({}, _base_0)
      mt.__init(self, ...)
      return self
    end })
end)()
local Yikes = (function(_parent_0)
  local _base_0 = {  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, getmetatable(_parent_0).__index)
  end
  return setmetatable({ __init = function(self) return print("created hello") end }, { __index = _base_0, __call = function(mt, ...)
      local self = setmetatable({}, _base_0)
      mt.__init(self, ...)
      return self
    end })
end)(Simple)
x = Yikes()
x:cool()