local util = require("moonscript.util")
local data = require("moonscript.data")
local ntype
ntype = require("moonscript.types").ntype
local user_error
user_error = require("moonscript.errors").user_error
local concat, insert
do
  local _obj_0 = table
  concat, insert = _obj_0.concat, _obj_0.insert
end
local unpack
unpack = util.unpack
local table_delim = ","
local string_chars = {
  ["\r"] = "\\r",
  ["\n"] = "\\n"
}
return {
  scoped = function(self, node)
    local _, before, value, after
    _, before, value, after = node[1], node[2], node[3], node[4]
    _ = before and before:call(self)
    do
      local _with_0 = self:value(value)
      _ = after and after:call(self)
      return _with_0
    end
  end,
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
        local _len_0 = 1
        for i, v in ipairs(node) do
          if i > 1 then
            _accum_0[_len_0] = _comp(i, v)
            _len_0 = _len_0 + 1
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
        local _len_0 = 1
        for _index_0 = 2, #node do
          local v = node[_index_0]
          _accum_0[_len_0] = self:value(v)
          _len_0 = _len_0 + 1
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
    local delim, inner = unpack(node, 2)
    local end_delim = delim:gsub("%[", "]")
    if delim == "'" or delim == '"' then
      inner = inner:gsub("[\r\n]", string_chars)
    end
    return delim .. inner .. end_delim
  end,
  chain = function(self, node)
    local callee = node[2]
    local callee_type = ntype(callee)
    local item_offset = 3
    if callee_type == "dot" or callee_type == "colon" or callee_type == "index" then
      callee = self:get("scope_var")
      if not (callee) then
        user_error("Short-dot syntax must be called within a with block")
      end
      item_offset = 2
    end
    if callee_type == "ref" and callee[2] == "super" or callee == "super" then
      do
        local sup = self:get("super")
        if sup then
          return self:value(sup(self, node))
        end
      end
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
        return ":", tostring(arg)
      elseif t == "colon_stub" then
        return user_error("Uncalled colon stub")
      else
        return error("Unknown chain action: " .. tostring(t))
      end
    end
    if (callee_type == "self" or callee_type == "self_class") and node[3] and ntype(node[3]) == "call" then
      callee[1] = callee_type .. "_colon"
    end
    local callee_value = self:value(callee)
    if ntype(callee) == "exp" then
      callee_value = self:line("(", callee_value, ")")
    end
    local actions
    do
      local _with_0 = self:line()
      for _index_0 = item_offset, #node do
        local action = node[_index_0]
        _with_0:append(chain_item(action))
      end
      actions = _with_0
    end
    return self:line(callee_value, actions)
  end,
  fndef = function(self, node)
    local args, whitelist, arrow, block = unpack(node, 2)
    local default_args = { }
    local self_args = { }
    local arg_names
    do
      local _accum_0 = { }
      local _len_0 = 1
      for _index_0 = 1, #args do
        local arg = args[_index_0]
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
        _accum_0[_len_0] = _value_0
        _len_0 = _len_0 + 1
      end
      arg_names = _accum_0
    end
    if arrow == "fat" then
      insert(arg_names, 1, "self")
    end
    do
      local _with_0 = self:block()
      if #whitelist > 0 then
        _with_0:whitelist_names(whitelist)
      end
      for _index_0 = 1, #arg_names do
        local name = arg_names[_index_0]
        _with_0:put_name(name)
      end
      for _index_0 = 1, #default_args do
        local default = default_args[_index_0]
        local name, value = unpack(default)
        if type(name) == "table" then
          name = name[2]
        end
        _with_0:stm({
          'if',
          {
            'exp',
            {
              "ref",
              name
            },
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
      local self_arg_values
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #self_args do
          local arg = self_args[_index_0]
          _accum_0[_len_0] = arg[2]
          _len_0 = _len_0 + 1
        end
        self_arg_values = _accum_0
      end
      if #self_args > 0 then
        _with_0:stm({
          "assign",
          self_args,
          self_arg_values
        })
      end
      _with_0:stms(block)
      if #args > #arg_names then
        do
          local _accum_0 = { }
          local _len_0 = 1
          for _index_0 = 1, #args do
            local arg = args[_index_0]
            _accum_0[_len_0] = arg[1]
            _len_0 = _len_0 + 1
          end
          arg_names = _accum_0
        end
      end
      _with_0.header = "function(" .. concat(arg_names, ", ") .. ")"
      return _with_0
    end
  end,
  table = function(self, node)
    local items = unpack(node, 2)
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
          local out = self:line(assign, " = ", _with_0:value(value))
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
  temp_name = function(self, node, ...)
    return node:get_name(self, ...)
  end,
  number = function(self, node)
    return node[2]
  end,
  bitnot = function(self, node)
    return self:line("~", self:value(node[2]))
  end,
  length = function(self, node)
    return self:line("#", self:value(node[2]))
  end,
  ["not"] = function(self, node)
    return self:line("not ", self:value(node[2]))
  end,
  self = function(self, node)
    return "self." .. self:name(node[2])
  end,
  self_class = function(self, node)
    return "self.__class." .. self:name(node[2])
  end,
  self_colon = function(self, node)
    return "self:" .. self:name(node[2])
  end,
  self_class_colon = function(self, node)
    return "self.__class:" .. self:name(node[2])
  end,
  ref = function(self, value)
    do
      local sup = value[2] == "super" and self:get("super")
      if sup then
        return self:value(sup(self))
      end
    end
    return tostring(value[2])
  end,
  raw_value = function(self, value)
    if value == "..." then
      self:send("varargs")
    end
    return tostring(value)
  end
}
