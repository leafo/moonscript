local lua = {
  debug = debug,
  type = type
}
local getfenv, setfenv, dump
do
  local _obj_0 = require("moonscript.util")
  getfenv, setfenv, dump = _obj_0.getfenv, _obj_0.setfenv, _obj_0.dump
end
local p, is_object, type, debug, run_with_scope, bind_methods, defaultbl, extend, copy, mixin, mixin_object, mixin_table, fold
p = function(o, ...)
  print(dump(o))
  if select("#", ...) > 0 then
    return p(...)
  end
end
is_object = function(value)
  return lua.type(value) == "table" and value.__class
end
type = function(value)
  local base_type = lua.type(value)
  if base_type == "table" then
    local cls = value.__class
    if cls then
      return cls
    end
  end
  return base_type
end
debug = setmetatable({
  upvalue = function(fn, k, ...)
    local value = nil
    local i = 1
    while true do
      local name
      name, value = lua.debug.getupvalue(fn, i)
      if name == nil then
        error("Failed to find upvalue: " .. tostring(k))
      end
      if name == k then
        break
      end
      i = i + 1
    end
    if select("#", ...) == 0 then
      return value
    else
      return lua.debug.setupvalue(fn, i, ...)
    end
  end
}, {
  __index = lua.debug
})
run_with_scope = function(fn, scope, ...)
  local old_env = getfenv(fn)
  local env = setmetatable({ }, {
    __index = function(self, name)
      local val = scope[name]
      if val ~= nil then
        return val
      else
        return old_env[name]
      end
    end
  })
  setfenv(fn, env)
  return fn(...)
end
bind_methods = function(obj)
  return setmetatable({ }, {
    __index = function(self, name)
      local val = obj[name]
      if val and lua.type(val) == "function" then
        local bound
        bound = function(...)
          return val(obj, ...)
        end
        self[name] = bound
        return bound
      else
        return val
      end
    end
  })
end
defaultbl = function(t, fn)
  if not fn then
    fn = t
    t = { }
  end
  return setmetatable(t, {
    __index = function(self, name)
      local val = fn(self, name)
      rawset(self, name, val)
      return val
    end
  })
end
extend = function(...)
  local tbls = {
    ...
  }
  if #tbls < 2 then
    return 
  end
  for i = 1, #tbls - 1 do
    local a = tbls[i]
    local b = tbls[i + 1]
    setmetatable(a, {
      __index = b
    })
  end
  return tbls[1]
end
copy = function(self)
  local _tbl_0 = { }
  for key, val in pairs(self) do
    _tbl_0[key] = val
  end
  return _tbl_0
end
mixin = function(self, cls, ...)
  for key, val in pairs(cls.__base) do
    if not key:match("^__") then
      self[key] = val
    end
  end
  return cls.__init(self, ...)
end
mixin_object = function(self, object, methods)
  for _index_0 = 1, #methods do
    local name = methods[_index_0]
    self[name] = function(parent, ...)
      return object[name](object, ...)
    end
  end
end
mixin_table = function(self, tbl, keys)
  if keys then
    for _index_0 = 1, #keys do
      local key = keys[_index_0]
      self[key] = tbl[key]
    end
  else
    for key, val in pairs(tbl) do
      self[key] = val
    end
  end
end
fold = function(items, fn)
  local len = #items
  if len > 1 then
    local accum = fn(items[1], items[2])
    for i = 3, len do
      accum = fn(accum, items[i])
    end
    return accum
  else
    return items[1]
  end
end
return {
  dump = dump,
  p = p,
  is_object = is_object,
  type = type,
  debug = debug,
  run_with_scope = run_with_scope,
  bind_methods = bind_methods,
  defaultbl = defaultbl,
  extend = extend,
  copy = copy,
  mixin = mixin,
  mixin_object = mixin_object,
  mixin_table = mixin_table,
  fold = fold
}
