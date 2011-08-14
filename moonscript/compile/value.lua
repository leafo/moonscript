module("moonscript.compile", package.seeall)
local util = require("moonscript.util")
local data = require("moonscript.data")
local dump = require("moonscript.dump")
require("moonscript.compile.format")
local ntype = data.ntype
local concat, insert = table.concat, table.insert
local table_append
table_append = function(name, len, value)
  return {
    {
      "update",
      len,
      "+=",
      1
    },
    {
      "assign",
      {
        {
          "chain",
          name,
          {
            "index",
            len
          }
        }
      },
      {
        value
      }
    }
  }
end
local create_accumulate_wrapper
create_accumulate_wrapper = function(block_pos)
  return function(self, node)
    do
      local _with_0 = self:block("(function()", "end)()")
      local accum_name = _with_0:init_free_var("accum", {
        "table"
      })
      local count_name = _with_0:init_free_var("len", 0)
      local value_name = _with_0:free_name("value", true)
      local inner = node[block_pos]
      inner[#inner] = {
        "assign",
        {
          value_name
        },
        {
          inner[#inner]
        }
      }
      insert(inner, {
        "if",
        {
          "exp",
          value_name,
          "~=",
          "nil"
        },
        table_append(accum_name, count_name, value_name)
      })
      _with_0:stm(node)
      _with_0:stm({
        "return",
        accum_name
      })
      return _with_0
    end
  end
end
value_compile = {
  exp = function(self, node)
    local _comp
    _comp = function(i, value)
      if i % 2 == 1 and value == "!=" then
        value = "~="
      end
      return self:value(value)
    end
    do
      local _with_0 = self:line()
      _with_0:append_list((function()
        local _accum_0 = { }
        local _len_0 = 0
        for i, v in ipairs(node) do
          if i > 1 then
            _len_0 = _len_0 + 1
            _accum_0[_len_0] = _comp(i, v)
          end
        end
        return _accum_0
      end)(), " ")
      return _with_0
    end
  end,
  update = function(self, node)
    local _, name = unpack(node)
    self:stm(node)
    return self:name(name)
  end,
  explist = function(self, node)
    do
      local _with_0 = self:line()
      _with_0:append_list((function()
        local _accum_0 = { }
        local _len_0 = 0
        do
          local _item_0 = node
          for _index_0 = 2, #_item_0 do
            local v = _item_0[_index_0]
            _len_0 = _len_0 + 1
            _accum_0[_len_0] = self:value(v)
          end
        end
        return _accum_0
      end)(), ", ")
      return _with_0
    end
  end,
  parens = function(self, node)
    return self:line("(", self:value(node[2]), ")")
  end,
  string = function(self, node)
    local _, delim, inner, delim_end = unpack(node)
    return delim .. inner .. (delim_end or delim)
  end,
  with = function(self, node)
    do
      local _with_0 = self:block("(function()", "end)()")
      _with_0:stm(node, default_return)
      return _with_0
    end
  end,
  ["if"] = function(self, node)
    do
      local _with_0 = self:block("(function()", "end)()")
      _with_0:stm(node, default_return)
      return _with_0
    end
  end,
  comprehension = function(self, node)
    local _, exp, iter = unpack(node)
    do
      local _with_0 = self:block()
      local tmp_name = _with_0:init_free_var("accum", {
        "table"
      })
      local len_name = _with_0:init_free_var("len", 0)
      local action
      action = function(value)
        return table_append(tmp_name, len_name, value)
      end
      _with_0:stm(node, action)
      _with_0:stm({
        "return",
        tmp_name
      })
      if _with_0.has_varargs then
        _with_0.header, _with_0.footer = "(function(...)", "end)(...)"
      else
        _with_0.header, _with_0.footer = "(function()", "end)()"
      end
      return _with_0
    end
  end,
  ["for"] = create_accumulate_wrapper(4),
  foreach = create_accumulate_wrapper(4),
  ["while"] = create_accumulate_wrapper(3),
  chain = function(self, node)
    local callee = node[2]
    if callee == -1 then
      callee = self:get("scope_var")
      if not callee then
        user_error("Short-dot syntax must be called within a with block")
      end
    end
    local sup = self:get("super")
    if callee == "super" and sup then
      return self:value(sup(self, node))
    end
    local chain_item
    chain_item = function(node)
      local t, arg = unpack(node)
      if t == "call" then
        return "(", self:values(arg), ")"
      elseif t == "index" then
        return "[", self:value(arg), "]"
      elseif t == "dot" then
        return ".", arg
      elseif t == "colon" then
        return ":", arg, chain_item(node[3])
      elseif t == "colon_stub" then
        return user_error("Uncalled colon stub")
      else
        return error("Unknown chain action: " .. t)
      end
    end
    local actions
    do
      local _with_0 = self:line()
      do
        local _item_0 = node
        for _index_0 = 3, #_item_0 do
          local action = _item_0[_index_0]
          _with_0:append(chain_item(action))
        end
      end
      actions = _with_0
    end
    if ntype(callee) == "self" and node[3] and ntype(node[3]) == "call" then
      callee[1] = "self_colon"
    end
    local callee_value = self:name(callee)
    if ntype(callee) == "exp" then
      callee_value = self:line("(", callee_value, ")")
    end
    return self:line(callee_value, actions)
  end,
  fndef = function(self, node)
    local _, args, whitelist, arrow, block = unpack(node)
    local default_args = { }
    local format_names
    format_names = function(arg)
      if type(arg) == "string" then
        return arg
      else
        insert(default_args, arg)
        return arg[1]
      end
    end
    args = (function()
      local _accum_0 = { }
      local _len_0 = 0
      do
        local _item_0 = args
        for _index_0 = 1, #_item_0 do
          local arg = _item_0[_index_0]
          _len_0 = _len_0 + 1
          _accum_0[_len_0] = format_names(arg)
        end
      end
      return _accum_0
    end)()
    if arrow == "fat" then
      insert(args, 1, "self")
    end
    do
      local _with_0 = self:block("function(" .. concat(args, ", ") .. ")")
      if #whitelist > 0 then
        _with_0:whitelist_names(whitelist)
      end
      do
        local _item_0 = args
        for _index_0 = 1, #_item_0 do
          local name = _item_0[_index_0]
          _with_0:put_name(name)
        end
      end
      do
        local _item_0 = default_args
        for _index_0 = 1, #_item_0 do
          local default = _item_0[_index_0]
          local name, value = unpack(default)
          _with_0:stm({
            'if',
            {
              'exp',
              name,
              '==',
              'nil'
            },
            {
              {
                'assign',
                {
                  name
                },
                {
                  value
                }
              }
            }
          })
        end
      end
      _with_0:ret_stms(block)
      return _with_0
    end
  end,
  table = function(self, node)
    local _, items = unpack(node)
    do
      local _with_0 = self:block("{", "}")
      _with_0.delim = ","
      local format_line
      format_line = function(tuple)
        if #tuple == 2 then
          local key, value = unpack(tuple)
          if type(key) == "string" and data.lua_keywords[key] then
            key = {
              "string",
              '"',
              key
            }
          end
          local assign
          if type(key) ~= "string" then
            assign = self:line("[", _with_0:value(key), "]")
          else
            assign = key
          end
          _with_0:set("current_block", key)
          local out = self:line(assign, " = ", _with_0:value(value))
          _with_0:set("current_block", nil)
          return out
        else
          return self:line(_with_0:value(tuple[1]))
        end
      end
      if items then
        do
          local _item_0 = items
          for _index_0 = 1, #_item_0 do
            local line = _item_0[_index_0]
            _with_0:add(format_line(line))
          end
        end
      end
      return _with_0
    end
  end,
  minus = function(self, node)
    return self:line("-", self:value(node[2]))
  end,
  number = function(self, node)
    return node[2]
  end,
  length = function(self, node)
    return self:line("#", self:value(node[2]))
  end,
  ["not"] = function(self, node)
    return self:line("not ", self:value(node[2]))
  end,
  self = function(self, node)
    return "self." .. self:value(node[2])
  end,
  self_colon = function(self, node)
    return "self:" .. self:value(node[2])
  end,
  raw_value = function(self, value)
    if value == "..." then
      self.has_varargs = true
    end
    return tostring(value)
  end
}
