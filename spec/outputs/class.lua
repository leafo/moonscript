local Hello
do
  local _class_0
  local _base_0 = {
    hello = function(self)
      return print(self.test, self.world)
    end,
    __tostring = function(self)
      return "hello world"
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, test, world)
      self.test, self.world = test, world
      return print("creating object..")
    end,
    __base = _base_0,
    __name = "Hello"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Hello = _class_0
end
local x = Hello(1, 2)
x:hello()
print(x)
local Simple
do
  local _class_0
  local _base_0 = {
    cool = function(self)
      return print("cool")
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Simple"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Simple = _class_0
end
local Yikes
do
  local _class_0
  local _parent_0 = Simple
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self)
      return print("created hello")
    end,
    __base = _base_0,
    __name = "Yikes",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
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
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Yikes = _class_0
end
x = Yikes()
x:cool()
local Hi
do
  local _class_0
  local _base_0 = {
    cool = function(self, num)
      return print("num", num)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, arg)
      return print("init arg", arg)
    end,
    __base = _base_0,
    __name = "Hi"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Hi = _class_0
end
do
  local _class_0
  local _parent_0 = Hi
  local _base_0 = {
    cool = function(self)
      return _class_0.__parent.__base.cool(self, 120302)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self)
      return _class_0.__parent.__init(self, "man")
    end,
    __base = _base_0,
    __name = "Simple",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
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
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Simple = _class_0
end
x = Simple()
x:cool()
print(x.__class == Simple)
local Okay
do
  local _class_0
  local _base_0 = {
    something = 20323
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Okay"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Okay = _class_0
end
local Biggie
do
  local _class_0
  local _parent_0 = Okay
  local _base_0 = {
    something = function(self)
      _class_0.__parent.__base.something(self, 1, 2, 3, 4)
      _class_0.__parent.something(another_self, 1, 2, 3, 4)
      return assert(_class_0.__parent == Okay)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Biggie",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
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
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Biggie = _class_0
end
local Yeah
do
  local _class_0
  local _base_0 = {
    okay = function(self)
      return _class_0.__parent.something(self, 1, 2, 3, 4)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Yeah"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Yeah = _class_0
end
local What
do
  local _class_0
  local _base_0 = {
    something = function(self)
      return print("val:", self.val)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "What"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  What = _class_0
end
do
  local _class_0
  local _parent_0 = What
  local _base_0 = {
    val = 2323,
    something = function(self)
      local _base_1 = _class_0.__parent
      local _fn_0 = _base_1.something
      return function(...)
        return _fn_0(self, ...)
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Hello",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
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
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Hello = _class_0
end
do
  local _with_0 = Hello()
  x = _with_0:something()
  print(x)
  x()
end
local CoolSuper
do
  local _class_0
  local _base_0 = {
    hi = function(self)
      _class_0.__parent.__base.hi(self, 1, 2, 3, 4)(1, 2, 3, 4)
      _class_0.__parent.something(1, 2, 3, 4)
      local _ = _class_0.__parent.something(1, 2, 3, 4).world
      _class_0.__parent.yeah(self, "world").okay(hi, hi, hi)
      _ = something.super
      _ = _class_0.__parent.super.super.super
      do
        local _base_1 = _class_0.__parent
        local _fn_0 = _base_1.hello
        _ = function(...)
          return _fn_0(self, ...)
        end
      end
      return nil
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "CoolSuper"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  CoolSuper = _class_0
end
x = self.hello
x = self.__class.hello
self:hello("world")
self.__class:hello("world")
self.__class:one(self.__class:two(4, 5)(self.three, self.four))
local xx
xx = function(hello, world, cool)
  self.hello, self.__class.world = hello, world
end
local ClassMan
do
  local _class_0
  local _base_0 = {
    blue = function(self) end,
    green = function(self) end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "ClassMan"
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
  self.yeah = 343
  self.hello = 3434
  self.world = 23423
  self.red = function(self) end
  ClassMan = _class_0
end
x = self
local y = self.__class
self(something)
self.__class(something)
local self = self + self / self
self = 343
self.hello(2, 3, 4)
local _ = hello[self].world
local Whacko
do
  local _class_0
  local hello
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Whacko"
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
  _ = self.hello
  if something then
    print("hello world")
  end
  hello = "world"
  self.another = "day"
  if something then
    print("yeah")
  end
  Whacko = _class_0
end
print("hello")
local yyy
yyy = function()
  local Cool
  do
    local _class_0
    local _base_0 = { }
    _base_0.__index = _base_0
    _class_0 = setmetatable({
      __init = function() end,
      __base = _base_0,
      __name = "Cool"
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
    _ = nil
    Cool = _class_0
    return _class_0
  end
end
do
  local _class_0
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "D"
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
  _ = nil
  a.b.c.D = _class_0
end
do
  local _class_0
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "hello"
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
  _ = nil
  a.b["hello"] = _class_0
end
do
  local _class_0
  local _parent_0 = Hello.World
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Something",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
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
  local self = _class_0
  _ = nil
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  (function()
    return require("moon")
  end)().Something = _class_0
end
local a
do
  local _class_0
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "a"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  a = _class_0
end
local b
local Something
do
  local _class_0
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Something"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Something = _class_0
  b = _class_0
end
local c
do
  local _class_0
  local _parent_0 = Hello
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Something",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
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
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Something = _class_0
  c = _class_0
end
local d
do
  local _class_0
  local _parent_0 = World
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "d",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
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
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  d = _class_0
end
print(((function()
  local WhatsUp
  do
    local _class_0
    local _base_0 = { }
    _base_0.__index = _base_0
    _class_0 = setmetatable({
      __init = function() end,
      __base = _base_0,
      __name = "WhatsUp"
    }, {
      __index = _base_0,
      __call = function(cls, ...)
        local _self_0 = setmetatable({}, _base_0)
        cls.__init(_self_0, ...)
        return _self_0
      end
    })
    _base_0.__class = _class_0
    WhatsUp = _class_0
    return _class_0
  end
end)()).__name)
do
  local _class_0
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Something"
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
  _ = nil
  Something = _class_0
end
do
  local _class_0
  local val, insert
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      return print(insert, val)
    end,
    __base = _base_0,
    __name = "Something"
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
  val = 23
  insert = table.insert
  Something = _class_0
end
do
  local _class_0
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = hi,
    __base = _base_0,
    __name = "X"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  X = _class_0
end
do
  local _class_0
  local _parent_0 = Thing
  local _base_0 = {
    dang = function(self)
      return {
        hello = function()
          return _class_0.__parent.__base.dang(self)
        end,
        world = function()
          return _class_0.__parent.one
        end
      }
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Cool",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
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
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Cool = _class_0
end
do
  local _class_0
  local _parent_0 = Thing
  local _base_0 = {
    dang = do_something(function(self)
      return _class_0.__parent.__base.dang(self)
    end)
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Whack",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
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
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Whack = _class_0
end
do
  local _class_0
  local _parent_0 = Thing
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Wowha",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
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
  local self = _class_0
  self.butt = function()
    _class_0.__parent.butt(self)
    _ = _class_0.__parent.hello
    _class_0.__parent.hello(self)
    local _base_1 = _class_0.__parent
    local _fn_0 = _base_1.hello
    return function(...)
      return _fn_0(self, ...)
    end
  end
  self.zone = cool({
    function()
      _class_0.__parent.zone(self)
      _ = _class_0.__parent.hello
      _class_0.__parent.hello(self)
      local _base_1 = _class_0.__parent
      local _fn_0 = _base_1.hello
      return function(...)
        return _fn_0(self, ...)
      end
    end
  })
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Wowha = _class_0
end
return nil