module("moonscript.transform", package.seeall)
local types = require("moonscript.types")
local util = require("moonscript.util")
local data = require("moonscript.data")
local ntype, build = types.ntype, types.build
NameProxy = (function(_parent_0)
  local _base_0 = {
    get_name = function(self, scope)
      if not self.name then
        self.name = scope:free_name(self.prefix, true)
      end
      return self.name
    end,
    __tostring = function(self)
      if self.name then
        return ("name<%s>"):format(self.name)
      else
        return ("name<prefix(%s)>"):format(self.prefix)
      end
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, getmetatable(_parent_0).__index)
  end
  local _class_0 = setmetatable({
    __init = function(self, prefix)
      self.prefix = prefix
      self[1] = "temp_name"
    end
  }, {
    __index = _base_0,
    __call = function(mt, ...)
      local self = setmetatable({}, _base_0)
      mt.__init(self, ...)
      return self
    end
  })
  _base_0.__class = _class_0
  return _class_0
end)()
local transformers = {
  chain = function(node)
    local stub = node[#node]
    if type(stub) == "table" and stub[1] == "colon_stub" then
      table.remove(node, #node)
      local base_name = NameProxy("base")
      local fn_name = NameProxy("fn")
      return build.block_exp({
        build.assign({
          names = {
            base_name
          },
          values = {
            node
          }
        }),
        build.assign({
          names = {
            fn_name
          },
          values = {
            build.chain({
              base = base_name,
              {
                "dot",
                stub[2]
              }
            })
          }
        }),
        build.fndef({
          args = {
            {
              "..."
            }
          },
          body = {
            build.chain({
              base = fn_name,
              {
                "call",
                {
                  base_name,
                  "..."
                }
              }
            })
          }
        })
      })
    end
  end
}
node = function(n)
  local transformer = transformers[ntype(n)]
  if transformer then
    return transformer(n) or n
  else
    return n
  end
end
