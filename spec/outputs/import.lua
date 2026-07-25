local hello
hello = yeah.hello
local world
do
  local _obj_0 = table["cool"]
  hello, world = _obj_0.hello, _obj_0.world
end
local a, b, c
do
  local _obj_0 = items
  a, b, c = _obj_0.a, (function()
    local _base_0 = _obj_0
    local _fn_0 = _base_0.b
    return function(...)
      return _fn_0(_base_0, ...)
    end
  end)(), _obj_0.c
end
local master, ghost
do
  local _obj_0 = find("mytable")
  master, ghost = _obj_0.master, (function()
    local _base_0 = _obj_0
    local _fn_0 = _base_0.ghost
    return function(...)
      return _fn_0(_base_0, ...)
    end
  end)()
end
local yumm
a, yumm = 3434, "hello"
local _table_0 = 232
local something
something = a(table).something
if indent then
  local okay, well
  do
    local _obj_0 = tables[100]
    okay, well = _obj_0.okay, (function()
      local _base_0 = _obj_0
      local _fn_0 = _base_0.well
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)()
  end
end
do
  do
    local _obj_0 = z
    a, b, c = _obj_0.a, _obj_0.b, _obj_0.c
  end
end
do
  do
    local _obj_0 = z
    a, b, c = _obj_0.a, _obj_0.b, _obj_0.c
  end
end
do
  do
    local _obj_0 = z
    a, b, c = _obj_0.a, _obj_0.b, _obj_0.c
  end
end
do
  do
    local _obj_0 = z
    a, b, c = _obj_0.a, _obj_0.b, _obj_0.c
  end
end
do
  do
    local _obj_0 = z
    a, b, c = _obj_0.a, _obj_0.b, _obj_0.c
  end
end
do
  local use, insert
  use = function()
    return insert("hello")
  end
  insert = table.insert
end
local Pipeline
do
  local _class_0
  local insert
  local _base_0 = {
    add = function(self, ...)
      return insert(self, ...)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Pipeline"
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
  insert = table.insert
  Pipeline = _class_0
  return _class_0
end