local types = require("moonscript.types")
local build, ntype, NOOP
build, ntype, NOOP = types.build, types.ntype, types.NOOP
local NameProxy
NameProxy = require("moonscript.transform.names").NameProxy
local insert
insert = table.insert
local is_singular
is_singular = function(body)
  if #body ~= 1 then
    return false
  end
  if "group" == ntype(body) then
    return is_singular(body[2])
  else
    return body[1]
  end
end
local transform_last_stm
transform_last_stm = require("moonscript.transform.statements").transform_last_stm
local Accumulator
do
  local _class_0
  local _base_0 = {
    body_idx = {
      ["for"] = 4,
      ["while"] = 3,
      foreach = 4
    },
    convert = function(self, node)
      local index = self.body_idx[ntype(node)]
      node[index] = self:mutate_body(node[index])
      return self:wrap(node)
    end,
    wrap = function(self, node, group_type)
      if group_type == nil then
        group_type = "block_exp"
      end
      return build[group_type]({
        build.assign_one(self.accum_name, build.table()),
        build.assign_one(self.len_name, 1),
        node,
        group_type == "block_exp" and self.accum_name or NOOP
      })
    end,
    mutate_body = function(self, body)
      local single_stm = is_singular(body)
      local val
      if single_stm and types.is_value(single_stm) then
        body = { }
        val = single_stm
      else
        body = transform_last_stm(body, function(n)
          if types.is_value(n) then
            return build.assign_one(self.value_name, n)
          else
            return build.group({
              {
                "declare",
                {
                  self.value_name
                }
              },
              n
            })
          end
        end)
        val = self.value_name
      end
      local update = {
        build.assign_one(NameProxy.index(self.accum_name, self.len_name), val),
        {
          "update",
          self.len_name,
          "+=",
          1
        }
      }
      insert(body, build.group(update))
      return body
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, accum_name)
      self.accum_name = NameProxy("accum")
      self.value_name = NameProxy("value")
      self.len_name = NameProxy("len")
    end,
    __base = _base_0,
    __name = "Accumulator"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Accumulator = _class_0
end
local default_accumulator
default_accumulator = function(self, node)
  return Accumulator():convert(node)
end
return {
  Accumulator = Accumulator,
  default_accumulator = default_accumulator
}
