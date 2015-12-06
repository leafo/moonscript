local util = require("moonscript.util")
local Set
Set = require("moonscript.data").Set
local insert
insert = table.insert
local unpack
unpack = util.unpack
local manual_return = Set({
  "foreach",
  "for",
  "while",
  "return"
})
local cascading = Set({
  "if",
  "unless",
  "with",
  "switch",
  "class",
  "do"
})
local terminating = Set({
  "return",
  "break"
})
local ntype
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
local mtype
do
  local moon_type = util.moon.type
  mtype = function(val)
    local mt = getmetatable(val)
    if mt and mt.smart_node then
      return "table"
    end
    return moon_type(val)
  end
end
local value_can_be_statement
value_can_be_statement = function(node)
  if not (ntype(node) == "chain") then
    return false
  end
  return ntype(node[#node]) == "call"
end
local is_value
is_value = function(stm)
  local compile = require("moonscript.compile")
  local transform = require("moonscript.transform")
  return compile.Block:is_value(stm) or transform.Value:can_transform(stm)
end
local value_is_singular
value_is_singular = function(node)
  return type(node) ~= "table" or node[1] ~= "exp" or #node == 2
end
local is_slice
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
local build = nil
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
    for _index_0 = 1, #tbl do
      local tuple = tbl[_index_0]
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
    if type(base) == "string" then
      base = {
        "ref",
        base
      }
    end
    local node = {
      "chain",
      base
    }
    for _index_0 = 1, #parts do
      local part = parts[_index_0]
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
local smart_node_mt = setmetatable({ }, {
  __index = function(self, node_type)
    local index = key_table[node_type]
    local mt = {
      smart_node = true,
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
    }
    self[node_type] = mt
    return mt
  end
})
local smart_node
smart_node = function(node)
  return setmetatable(node, smart_node_mt[ntype(node)])
end
local NOOP = {
  "noop"
}
return {
  ntype = ntype,
  smart_node = smart_node,
  build = build,
  is_value = is_value,
  is_slice = is_slice,
  manual_return = manual_return,
  cascading = cascading,
  value_is_singular = value_is_singular,
  value_can_be_statement = value_can_be_statement,
  mtype = mtype,
  terminating = terminating,
  NOOP = NOOP
}
