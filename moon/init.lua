if not moon or not moon.inject then
  print("wrapping")
  module("moon", package.seeall)
end
local util = require("moonscript.util")
dump = util.dump
run_with_scope = function(fn, scope)
  local old_env = getfenv(fn)
  local env = setmetatable({ }, {
    __index = function(self, name)
      print("indexing ", name)
      local val = scope[name]
      if val then
        return val
      else
        return old_env[name]
      end
    end
  })
  setfenv(fn, env)
  return fn()
end
bound_methods = function(obj)
  return setmetatable({ }, {
    __index = function(self, name)
      local val = obj[name]
      if val and type(val) == "function" then
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
