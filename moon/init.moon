
lua = { :debug, :type }
import getfenv, setfenv, dump from require "moonscript.util"

local *

p = (...) ->
  print dump ...

is_object =  (value) -> -- is a moonscript object
  lua.type(value) == "table" and value.__class

type = (value) -> -- class aware type
  base_type = lua.type value
  if base_type == "table"
    cls = value.__class
    return cls if cls
  base_type

debug = setmetatable {
  upvalue: (fn, k, v) ->
    upvalues = {}
    i = 1
    while true
      name = lua.debug.getupvalue(fn, i)
      break if name == nil
      upvalues[name] = i
      i += 1

    if not upvalues[k]
      error "Failed to find upvalue: " .. tostring k

    if not v
      _, value = lua.debug.getupvalue fn, upvalues[k]
      value
    else
      lua.debug.setupvalue fn, upvalues[k], v
}, __index: lua.debug

-- run a function with scope injected before its function environment
run_with_scope = (fn, scope, ...) ->
  old_env = getfenv fn
  env = setmetatable {}, {
    __index: (name) =>
      val = scope[name]
      if val != nil
        val
      else
        old_env[name]
  }
  setfenv fn, env
  fn ...

-- wrap obj such that calls to methods do not need a reference to self
bind_methods = (obj) ->
  setmetatable {}, {
    __index: (name) =>
      val = obj[name]
      if val and lua.type(val) == "function"
        bound = (...) -> val obj, ...
        self[name] = bound
        bound
      else
        val
  }

-- use a function to provide default values to table
-- optionally specify a starting table
-- fibanocci table:
-- t = defaultbl {[0]: 0, [1]: 1}, (i) -> self[i - 1] + self[i - 2]
defaultbl = (t, fn) ->
  if not fn
    fn = t
    t = {}
  setmetatable t, {
    __index: (name) =>
      val = fn self, name
      rawset self, name, val
      val
  }

-- chain together tables by __index metatables
extend = (...) ->
  tbls = {...}
  return if #tbls < 2

  for i = 1, #tbls - 1
    a = tbls[i]
    b = tbls[i + 1]

    setmetatable a, __index: b

  tbls[1]

-- shallow copy
copy = =>
  {key,val for key,val in pairs self}

-- merges the content of the second table with the content in the second table
merge = (tbl) =>
  for k, v in pairs tbl
    self[k] = v
  self

-- mixin class properties into self, call new
mixin = (cls, ...) =>
  for key, val in pairs cls.__base
    self[key] = val if not key\match"^__"
  cls.__init self, ...

-- mixin methods from an object into self
mixin_object = (object, methods) =>
  for name in *methods
    self[name] = (parent, ...) ->
      object[name](object, ...)

-- mixin table values into self
mixin_table = (tbl, keys) =>
  if keys
    for key in *keys
      self[key] = tbl[key]
  else
    for key, val in pairs tbl
      self[key] = val

fold = (items, fn)->
  len = #items
  if len > 1
    accum = fn items[1], items[2]
    for i=3,len
      accum = fn accum, items[i]
    accum
  else
    items[1]

{
  :dump, :p, :is_object, :type, :debug, :run_with_scope, :bind_methods,
  :defaultbl, :extend, :copy, :mixin, :mixin_object, :mixin_table, :fold
}
