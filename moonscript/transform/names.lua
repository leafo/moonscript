local build
build = require("moonscript.types").build
local unpack
unpack = require("moonscript.util").unpack
local LocalName
do
  local _class_0
  local _base_0 = {
    get_name = function(self)
      return self.name
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, name)
      self.name = name
      self[1] = "temp_name"
    end,
    __base = _base_0,
    __name = "LocalName"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  LocalName = _class_0
end
local NameProxy
do
  local _class_0
  local _base_0 = {
    get_name = function(self, scope, dont_put)
      if dont_put == nil then
        dont_put = true
      end
      if not self.name then
        self.name = scope:free_name(self.prefix, dont_put)
      end
      return self.name
    end,
    chain = function(self, ...)
      local items = {
        base = self,
        ...
      }
      for k, v in ipairs(items) do
        if type(v) == "string" then
          items[k] = {
            "dot",
            v
          }
        else
          items[k] = v
        end
      end
      return build.chain(items)
    end,
    index = function(self, key)
      if type(key) == "string" then
        key = {
          "ref",
          key
        }
      end
      return build.chain({
        base = self,
        {
          "index",
          key
        }
      })
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
  _class_0 = setmetatable({
    __init = function(self, prefix)
      self.prefix = prefix
      self[1] = "temp_name"
    end,
    __base = _base_0,
    __name = "NameProxy"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  NameProxy = _class_0
end
local is_name_proxy
is_name_proxy = function(v)
  if not (type(v) == "table") then
    return false
  end
  local _exp_0 = v.__class
  if LocalName == _exp_0 or NameProxy == _exp_0 then
    return true
  end
end
return {
  NameProxy = NameProxy,
  LocalName = LocalName,
  is_name_proxy = is_name_proxy
}
