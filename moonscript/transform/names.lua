local build
do
  local _obj_0 = require("moonscript.types")
  build = _obj_0.build
end
local unpack
do
  local _obj_0 = require("moonscript.util")
  unpack = _obj_0.unpack
end
local LocalName
do
  local _base_0 = {
    get_name = function(self)
      return self.name
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
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
      local items
      do
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = {
          ...
        }
        for _index_0 = 1, #_list_0 do
          local i = _list_0[_index_0]
          if type(i) == "string" then
            _accum_0[_len_0] = {
              "dot",
              i
            }
          else
            _accum_0[_len_0] = i
          end
          _len_0 = _len_0 + 1
        end
        items = _accum_0
      end
      return build.chain({
        base = self,
        unpack(items)
      })
    end,
    index = function(self, key)
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
  local _class_0 = setmetatable({
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
return {
  NameProxy = NameProxy,
  LocalName = LocalName
}
