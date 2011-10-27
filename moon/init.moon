
if not moon or not moon.inject
  module "moon", package.seeall

util = require "moonscript.util"

export *

dump = util.dump

-- run a function with scope injected before its function environment
run_with_scope = (fn, scope, ...) ->
  old_env = getfenv fn
  env = setmetatable {}, {
    __index: (name) =>
      print "indexing ", name
      val = scope[name]
      if val != nil
        val
      else
        old_env[name]
  }
  setfenv fn, env
  fn ...

-- wrap obj such that calls to methods do not need a reference to self
bound_methods = (obj) ->
  setmetatable {}, {
    __index: (name) =>
      val = obj[name]
      if val and type(val) == "function"
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

-- helper function to set metatable with index
extend = (base) =>
  setmetatable self, __index: base

-- shallow copy
copy = =>
  t = {}
  for key, val in pairs self
    t[key] = val
  t

-- mixin class properties into self, call new
mixin = (cls, ...) =>
  meta = getmetatable cls
  for key, val in pairs meta.__index
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

