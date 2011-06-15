local Hello, _Hello_mt
_Hello_mt = { __tostring = function(self) return "hello world" end, __index = { hello = function(self) return print(self.test, self.world) end } }
Hello = function(test, world)
  local self = setmetatable({}, _Hello_mt)
  self.test, self.world = test, world
  print("creating object..")
  return self
end
local x = Hello(1, 2)
x:hello()
print(x)