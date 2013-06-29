local concat, remove, insert
do
  local _obj_0 = table
  concat, remove, insert = _obj_0.concat, _obj_0.remove, _obj_0.insert
end
local Set
Set = function(items)
  local self = { }
  for _index_0 = 1, #items do
    local key = items[_index_0]
    self[key] = true
  end
  return self
end
local Stack
do
  local _base_0 = {
    __tostring = function(self)
      return "<Stack {" .. concat(self, ", ") .. "}>"
    end,
    pop = function(self)
      return remove(self)
    end,
    push = function(self, value)
      insert(self, value)
      return value
    end,
    top = function(self)
      return self[#self]
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, ...)
      local _list_0 = {
        ...
      }
      for _index_0 = 1, #_list_0 do
        local v = _list_0[_index_0]
        self:push(v)
      end
      return nil
    end,
    __base = _base_0,
    __name = "Stack"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Stack = _class_0
end
local lua_keywords = Set({
  'and',
  'break',
  'do',
  'else',
  'elseif',
  'end',
  'false',
  'for',
  'function',
  'if',
  'in',
  'local',
  'nil',
  'not',
  'or',
  'repeat',
  'return',
  'then',
  'true',
  'until',
  'while'
})
return {
  Set = Set,
  Stack = Stack,
  lua_keywords = lua_keywords
}
