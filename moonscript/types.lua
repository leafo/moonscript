module("moonscript.types", package.seeall)
local util = require("moonscript.util")
local data = require("moonscript.data")
local insert = table.insert
manual_return = data.Set({
  "foreach",
  "for",
  "while",
  "return"
})
cascading = data.Set({
  "if",
  "unless",
  "with",
  "switch",
  "class",
  "do"
})
is_value = function(stm)
  local compile, transform = moonscript.compile, moonscript.transform
  return compile.Block:is_value(stm) or transform.Value:can_transform(stm)
end
comprehension_has_value = function(comp)
  return is_value(comp[2])
end
ntype = function(node)
  local _exp_0 = type(node)
  if "nil" == _exp_0 then
    return "nil"
  elseif "table" == _exp_0 then
    return node[1]
  else
    return "value"
  end
end
value_is_singular = function(node)
  return type(node) ~= "table" or node[1] ~= "exp" or #node == 2
end
is_slice = function(node)
  return ntype(node) == "chain" and ntype(node[#node]) == "slice"
end
local t = { }
local node_types = {
  class = {
    {
      "name",
      "Tmp"
    },
    {
      "body",
      t
    }
  },
  fndef = {
    {
      "args",
      t
    },
    {
      "whitelist",
      t
    },
    {
      "arrow",
      "slim"
    },
    {
      "body",
      t
    }
  },
  foreach = {
    {
      "names",
      t
    },
    {
      "iter"
    },
    {
      "body",
      t
    }
  },
  ["for"] = {
    {
      "name"
    },
    {
      "bounds",
      t
    },
    {
      "body",
      t
    }
  },
  ["while"] = {
    {
      "cond",
      t
    },
    {
      "body",
      t
    }
  },
  assign = {
    {
      "names",
      t
    },
    {
      "values",
      t
    }
  },
  declare = {
    {
      "names",
      t
    }
  },
  ["if"] = {
    {
      "cond",
      t
    },
    {
      "then",
      t
    }
  }
}
local build_table
build_table = function()
  local key_table = { }
  for node_name, args in pairs(node_types) do
    local index = { }
    for i, tuple in ipairs(args) do
      local prop_name = tuple[1]
      index[prop_name] = i + 1
    end
    key_table[node_name] = index
  end
  return key_table
end
local key_table = build_table()
local make_builder
make_builder = function(name)
  local spec = node_types[name]
  if not spec then
    error("don't know how to build node: " .. name)
  end
  return function(props)
    if props == nil then
      props = { }
    end
    local node = {
      name
    }
    for i, arg in ipairs(spec) do
      local key, default_value = unpack(arg)
      local val
      if props[key] then
        val = props[key]
      else
        val = default_value
      end
      if val == t then
        val = { }
      end
      node[i + 1] = val
    end
    return node
  end
end
build = nil
build = setmetatable({
  group = function(body)
    if body == nil then
      body = { }
    end
    return {
      "group",
      body
    }
  end,
  ["do"] = function(body)
    return {
      "do",
      body
    }
  end,
  assign_one = function(name, value)
    return build.assign({
      names = {
        name
      },
      values = {
        value
      }
    })
  end,
  table = function(tbl)
    if tbl == nil then
      tbl = { }
    end
    local _list_0 = tbl
    for _index_0 = 1, #_list_0 do
      local tuple = _list_0[_index_0]
      if type(tuple[1]) == "string" then
        tuple[1] = {
          "key_literal",
          tuple[1]
        }
      end
    end
    return {
      "table",
      tbl
    }
  end,
  block_exp = function(body)
    return {
      "block_exp",
      body
    }
  end,
  chain = function(parts)
    local base = parts.base or error("expecting base property for chain")
    local node = {
      "chain",
      base
    }
    local _list_0 = parts
    for _index_0 = 1, #_list_0 do
      local part = _list_0[_index_0]
      insert(node, part)
    end
    return node
  end
}, {
  __index = function(self, name)
    self[name] = make_builder(name)
    return rawget(self, name)
  end
})
smart_node = function(node)
  local index = key_table[ntype(node)]
  if not index then
    return node
  end
  return setmetatable(node, {
    __index = function(node, key)
      if index[key] then
        return rawget(node, index[key])
      elseif type(key) == "string" then
        return error("unknown key: `" .. key .. "` on node type: `" .. ntype(node) .. "`")
      end
    end,
    __newindex = function(node, key, value)
      if index[key] then
        key = index[key]
      end
      return rawset(node, key, value)
    end
  })
end
return nil
