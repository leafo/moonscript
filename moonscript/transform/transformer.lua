local ntype
ntype = require("moonscript.types").ntype
local Transformer
do
  local _class_0
  local _base_0 = {
    transform_once = function(self, scope, node, ...)
      if self.seen_nodes[node] then
        return node
      end
      self.seen_nodes[node] = true
      local transformer = self.transformers[ntype(node)]
      if transformer then
        return transformer(scope, node, ...) or node
      else
        return node
      end
    end,
    transform = function(self, scope, node, ...)
      if self.seen_nodes[node] then
        return node
      end
      self.seen_nodes[node] = true
      while true do
        local transformer = self.transformers[ntype(node)]
        local res
        if transformer then
          res = transformer(scope, node, ...) or node
        else
          res = node
        end
        if res == node then
          return node
        end
        node = res
      end
      return node
    end,
    bind = function(self, scope)
      return function(...)
        return self:transform(scope, ...)
      end
    end,
    __call = function(self, ...)
      return self:transform(...)
    end,
    can_transform = function(self, node)
      return self.transformers[ntype(node)] ~= nil
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, transformers)
      self.transformers = transformers
      self.seen_nodes = setmetatable({ }, {
        __mode = "k"
      })
    end,
    __base = _base_0,
    __name = "Transformer"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Transformer = _class_0
end
return {
  Transformer = Transformer
}
