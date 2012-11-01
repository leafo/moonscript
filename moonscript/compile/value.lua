module("moonscript.compile", package.seeall)
local util = require("moonscript.util")
local data = require("moonscript.data")
require("moonscript.compile.format")
local ntype
do
  local _table_0 = require("moonscript.types")
  ntype = _table_0.ntype
end
local concat, insert = table.concat, table.insert
local table_delim = ","
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
  explist = function(self, node)
    do
      local _with_0 = self:line()
      _with_0:append_list((function()
        local _accum_0 = { }
        local _len_0 = 0
        local _list_0 = node
        for _index_0 = 2, #_list_0 do
          local v = _list_0[_index_0]
          _len_0 = _len_0 + 1
          _accum_0[_len_0] = self:value(v)
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
    local _, delim, inner = unpack(node)
    local end_delim = delim:gsub("%[", "]")
    return delim .. inner .. end_delim
  end,
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
        return ".", tostring(arg)
      elseif t == "colon" then
        return ":", arg, chain_item(node[3])
      elseif t == "colon_stub" then
        return user_error("Uncalled colon stub")
      else
        return error("Unknown chain action: " .. t)
      end
    end
    local t = ntype(callee)
    if (t == "self" or t == "self_class") and node[3] and ntype(node[3]) == "call" then
      callee[1] = t .. "_colon"
    end
    local callee_value = self:value(callee)
    if ntype(callee) == "exp" then
      callee_value = self:line("(", callee_value, ")")
    end
    local actions
    do
      local _with_0 = self:line()
      local _list_0 = node
      for _index_0 = 3, #_list_0 do
        local action = _list_0[_index_0]
        _with_0:append(chain_item(action))
      end
      actions = _with_0
    end
    return self:line(callee_value, actions)
  end,
  fndef = function(self, node)
    local _, args, whitelist, arrow, block = unpack(node)
    local default_args = { }
    local self_args = { }
    local arg_names = (function()
      local _accum_0 = { }
      local _len_0 = 0
      local _list_0 = args
      for _index_0 = 1, #_list_0 do
        local arg = _list_0[_index_0]
        local name, default_value = unpack(arg)
        if type(name) == "string" then
          name = name
        else
          if name[1] == "self" or name[1] == "self_class" then
            insert(self_args, name)
          end
          name = name[2]
        end
        if default_value then
          insert(default_args, arg)
        end
        local _value_0 = name
        if _value_0 ~= nil then
          _len_0 = _len_0 + 1
          _accum_0[_len_0] = _value_0
        end
      end
      return _accum_0
    end)()
    if arrow == "fat" then
      insert(arg_names, 1, "self")
    end
    do
      local _with_0 = self:block()
      if #whitelist > 0 then
        _with_0:whitelist_names(whitelist)
      end
      local _list_0 = arg_names
      for _index_0 = 1, #_list_0 do
        local name = _list_0[_index_0]
        _with_0:put_name(name)
      end
      local _list_1 = default_args
      for _index_0 = 1, #_list_1 do
        local default = _list_1[_index_0]
        local name, value = unpack(default)
        if type(name) == "table" then
          name = name[2]
        end
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
      local self_arg_values = (function()
        local _accum_0 = { }
        local _len_0 = 0
        local _list_2 = self_args
        for _index_0 = 1, #_list_2 do
          local arg = _list_2[_index_0]
          _len_0 = _len_0 + 1
          _accum_0[_len_0] = arg[2]
        end
        return _accum_0
      end)()
      if #self_args > 0 then
        _with_0:stm({
          "assign",
          self_args,
          self_arg_values
        })
      end
      _with_0:stms(block)
      if #args > #arg_names then
        arg_names = (function()
          local _accum_0 = { }
          local _len_0 = 0
          local _list_2 = args
          for _index_0 = 1, #_list_2 do
            local arg = _list_2[_index_0]
            local _value_0 = arg[1]
            if _value_0 ~= nil then
              _len_0 = _len_0 + 1
              _accum_0[_len_0] = _value_0
            end
          end
          return _accum_0
        end)()
      end
      _with_0.header = "function(" .. concat(arg_names, ", ") .. ")"
      return _with_0
    end
  end,
  table = function(self, node)
    local _, items = unpack(node)
    do
      local _with_0 = self:block("{", "}")
      local format_line
      format_line = function(tuple)
        if #tuple == 2 then
          local key, value = unpack(tuple)
          if ntype(key) == "key_literal" and data.lua_keywords[key[2]] then
            key = {
              "string",
              '"',
              key[2]
            }
          end
          local assign
          if ntype(key) == "key_literal" then
            assign = key[2]
          else
            assign = self:line("[", _with_0:value(key), "]")
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
        local count = #items
        for i, tuple in ipairs(items) do
          local line = format_line(tuple)
          if not (count == i) then
            line:append(table_delim)
          end
          _with_0:add(line)
        end
      end
      return _with_0
    end
  end,
  minus = function(self, node)
    return self:line("-", self:value(node[2]))
  end,
  temp_name = function(self, node)
    return node:get_name(self)
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
  self_class = function(self, node)
    return "self.__class." .. self:value(node[2])
  end,
  self_colon = function(self, node)
    return "self:" .. self:value(node[2])
  end,
  self_class_colon = function(self, node)
    return "self.__class:" .. self:value(node[2])
  end,
  raw_value = function(self, value)
    local sup = self:get("super")
    if value == "super" and sup then
      return self:value(sup(self))
    end
    if value == "..." then
      self:send("varargs")
    end
    return tostring(value)
  end
}
