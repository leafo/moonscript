module("moonscript.compile", package.seeall)
local util = require("moonscript.util")
local dump = require("moonscript.dump")
require("moonscript.compile.format")
require("moonscript.compile.statement")
require("moonscript.compile.value")
local transform = require("moonscript.transform")
local NameProxy, LocalName = transform.NameProxy, transform.LocalName
local Set
do
  local _table_0 = require("moonscript.data")
  Set = _table_0.Set
end
local ntype
do
  local _table_0 = require("moonscript.types")
  ntype = _table_0.ntype
end
local concat, insert = table.concat, table.insert
local pos_to_line, get_closest_line, trim = util.pos_to_line, util.get_closest_line, util.trim
local Line
Line = (function()
  local _parent_0 = nil
  local _base_0 = {
    _append_single = function(self, item)
      if util.moon.type(item) == Line then
        local _list_0 = item
        for _index_0 = 1, #_list_0 do
          value = _list_0[_index_0]
          self:_append_single(value)
        end
      else
        insert(self, item)
      end
      return nil
    end,
    append_list = function(self, items, delim)
      for i = 1, #items do
        self:_append_single(items[i])
        if i < #items then
          insert(self, delim)
        end
      end
    end,
    append = function(self, ...)
      local _list_0 = {
        ...
      }
      for _index_0 = 1, #_list_0 do
        local item = _list_0[_index_0]
        self:_append_single(item)
      end
      return nil
    end,
    render = function(self)
      local buff = { }
      for i = 1, #self do
        local c = self[i]
        insert(buff, (function()
          if util.moon.type(c) == Block then
            c:bubble()
            return c:render()
          else
            return c
          end
        end)())
      end
      return concat(buff)
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self, ...)
      if _parent_0 then
        return _parent_0.__init(self, ...)
      end
    end,
    __base = _base_0,
    __name = "Line",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil and _parent_0 then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  return _class_0
end)()
Block = (function()
  local _parent_0 = nil
  local _base_0 = {
    header = "do",
    footer = "end",
    export_all = false,
    export_proper = false,
    __tostring = function(self)
      return "Block<> <- " .. tostring(self.parent)
    end,
    bubble = function(self, other)
      if other == nil then
        other = self.parent
      end
      local has_varargs = self.has_varargs and not self:has_name("...")
      other.has_varargs = other.has_varargs or has_varargs
    end,
    line_table = function(self)
      return self._posmap
    end,
    set = function(self, name, value)
      self._state[name] = value
    end,
    get = function(self, name)
      return self._state[name]
    end,
    declare = function(self, names)
      local undeclared = (function()
        local _accum_0 = { }
        local _len_0 = 0
        local _list_0 = names
        for _index_0 = 1, #_list_0 do
          local name = _list_0[_index_0]
          local is_local = false
          local real_name
          local _exp_0 = util.moon.type(name)
          if LocalName == _exp_0 then
            is_local = true
            real_name = name:get_name(self)
          elseif NameProxy == _exp_0 then
            real_name = name:get_name(self)
          elseif "string" == _exp_0 then
            real_name = name
          end
          local _value_0
          if is_local or real_name and not self:has_name(real_name) then
            _value_0 = real_name
          end
          if _value_0 ~= nil then
            _len_0 = _len_0 + 1
            _accum_0[_len_0] = _value_0
          end
        end
        return _accum_0
      end)()
      local _list_0 = undeclared
      for _index_0 = 1, #_list_0 do
        local name = _list_0[_index_0]
        self:put_name(name)
      end
      return undeclared
    end,
    whitelist_names = function(self, names)
      self._name_whitelist = Set(names)
    end,
    put_name = function(self, name)
      if util.moon.type(name) == NameProxy then
        name = name:get_name(self)
      end
      self._names[name] = true
    end,
    has_name = function(self, name, skip_exports)
      if not skip_exports then
        if self.export_all then
          return true
        end
        if self.export_proper and name:match("^[A-Z]") then
          return true
        end
      end
      local yes = self._names[name]
      if yes == nil and self.parent then
        if not self._name_whitelist or self._name_whitelist[name] then
          return self.parent:has_name(name, true)
        end
      else
        return yes
      end
    end,
    free_name = function(self, prefix, dont_put)
      prefix = prefix or "moon"
      local searching = true
      local name, i = nil, 0
      while searching do
        name = concat({
          "",
          prefix,
          i
        }, "_")
        i = i + 1
        searching = self:has_name(name, true)
      end
      if not dont_put then
        self:put_name(name)
      end
      return name
    end,
    init_free_var = function(self, prefix, value)
      local name = self:free_name(prefix, true)
      self:stm({
        "assign",
        {
          name
        },
        {
          value
        }
      })
      return name
    end,
    mark_pos = function(self, node)
      if node[-1] then
        self.last_pos = node[-1]
        if not self._posmap[self.current_line] then
          self._posmap[self.current_line] = self.last_pos
        end
      end
    end,
    add_line_text = function(self, text)
      return insert(self._lines, text)
    end,
    append_line_table = function(self, sub_table, offset)
      offset = offset + self.current_line
      for line, source in pairs(sub_table) do
        local line = line + offset
        if not self._posmap[line] then
          self._posmap[line] = source
        end
      end
    end,
    add_line_tables = function(self, line)
      local _list_0 = line
      for _index_0 = 1, #_list_0 do
        local chunk = _list_0[_index_0]
        if util.moon.type(chunk) == Block then
          local current = chunk
          while current do
            if util.moon.type(current.header) == Line then
              self:add_line_tables(current.header)
            end
            self:append_line_table(current:line_table(), 0)
            self.current_line = self.current_line + current.current_line
            current = current.next
          end
        end
      end
    end,
    add = function(self, line)
      local t = util.moon.type(line)
      if t == "string" then
        self:add_line_text(line)
      elseif t == Block then
        self:add(self:line(line))
      elseif t == Line then
        self:add_line_tables(line)
        self:add_line_text(line:render())
        self.current_line = self.current_line + 1
      else
        error("Adding unknown item")
      end
      return nil
    end,
    _insert_breaks = function(self)
      for i = 1, #self._lines - 1 do
        local left, right = self._lines[i], self._lines[i + 1]
        if left:sub(-1) == ")" and right:sub(1, 1) == "(" then
          self._lines[i] = self._lines[i] .. ";"
        end
      end
    end,
    render = function(self)
      local flatten
      flatten = function(line)
        if type(line) == "string" then
          return line
        else
          return line:render()
        end
      end
      local header = flatten(self.header)
      if #self._lines == 0 then
        local footer = flatten(self.footer)
        return concat({
          header,
          footer
        }, " ")
      end
      local indent = indent_char:rep(self.indent)
      if not self.delim then
        self:_insert_breaks()
      end
      local body = indent .. concat(self._lines, (self.delim or "") .. "\n" .. indent)
      return concat({
        header,
        body,
        indent_char:rep(self.indent - 1) .. (function()
          if self.next then
            return self.next:render()
          else
            return flatten(self.footer)
          end
        end)()
      }, "\n")
    end,
    block = function(self, header, footer)
      return Block(self, header, footer)
    end,
    line = function(self, ...)
      do
        local _with_0 = Line()
        _with_0:append(...)
        return _with_0
      end
    end,
    is_stm = function(self, node)
      return line_compile[ntype(node)] ~= nil
    end,
    is_value = function(self, node)
      local t = ntype(node)
      return value_compile[t] ~= nil or t == "value"
    end,
    name = function(self, node)
      return self:value(node)
    end,
    value = function(self, node, ...)
      node = self.root.transform.value(node)
      local action
      if type(node) ~= "table" then
        action = "raw_value"
      else
        self:mark_pos(node)
        action = node[1]
      end
      local fn = value_compile[action]
      if not fn then
        error("Failed to compile value: " .. dump.value(node))
      end
      return fn(self, node, ...)
    end,
    values = function(self, values, delim)
      delim = delim or ', '
      do
        local _with_0 = Line()
        _with_0:append_list((function()
          local _accum_0 = { }
          local _len_0 = 0
          local _list_0 = values
          for _index_0 = 1, #_list_0 do
            local v = _list_0[_index_0]
            _len_0 = _len_0 + 1
            _accum_0[_len_0] = self:value(v)
          end
          return _accum_0
        end)(), delim)
        return _with_0
      end
    end,
    stm = function(self, node, ...)
      if not node then
        return 
      end
      node = self.root.transform.statement(node)
      local fn = line_compile[ntype(node)]
      if not fn then
        if has_value(node) then
          self:stm({
            "assign",
            {
              "_"
            },
            {
              node
            }
          })
        else
          self:add(self:value(node))
        end
      else
        self:mark_pos(node)
        local out = fn(self, node, ...)
        if out then
          self:add(out)
        end
      end
      return nil
    end,
    stms = function(self, stms, ret)
      if ret then
        error("deprecated stms call, use transformer")
      end
      local _list_0 = stms
      for _index_0 = 1, #_list_0 do
        local stm = _list_0[_index_0]
        self:stm(stm)
      end
      return nil
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self, parent, header, footer)
      self.parent, self.header, self.footer = parent, header, footer
      self.current_line = 1
      self._lines = { }
      self._posmap = { }
      self._names = { }
      self._state = { }
      if self.parent then
        self.root = self.parent.root
        self.indent = self.parent.indent + 1
        return setmetatable(self._state, {
          __index = self.parent._state
        })
      else
        self.indent = 0
      end
    end,
    __base = _base_0,
    __name = "Block",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil and _parent_0 then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  return _class_0
end)()
local RootBlock
RootBlock = (function()
  local _parent_0 = Block
  local _base_0 = {
    __tostring = function(self)
      return "RootBlock<>"
    end,
    render = function(self)
      self:_insert_breaks()
      return concat(self._lines, "\n")
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self, ...)
      self.root = self
      self.transform = {
        value = transform.Value:instance(self),
        statement = transform.Statement:instance(self)
      }
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "RootBlock",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil and _parent_0 then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  return _class_0
end)()
format_error = function(msg, pos, file_str)
  local line = pos_to_line(file_str, pos)
  local line_str
  line_str, line = get_closest_line(file_str, line)
  line_str = line_str or ""
  return concat({
    "Compile error: " .. msg,
    (" [%d] >>    %s"):format(line, trim(line_str))
  }, "\n")
end
value = function(value)
  local out = nil
  do
    local _with_0 = RootBlock()
    _with_0:add(_with_0:value(value))
    out = _with_0:render()
  end
  return out
end
tree = function(tree)
  local scope = RootBlock()
  local runner = coroutine.create(function()
    local _list_0 = tree
    for _index_0 = 1, #_list_0 do
      local line = _list_0[_index_0]
      scope:stm(line)
    end
    return scope:render()
  end)
  local success, result = coroutine.resume(runner)
  if not success then
    local error_msg
    if type(result) == "table" then
      local error_type = result[1]
      if error_type == "user-error" then
        error_msg = result[2]
      else
        error_msg = error("Unknown error thrown", util.dump(error_msg))
      end
    else
      error_msg = concat({
        result,
        debug.traceback(runner)
      }, "\n")
    end
    return nil, error_msg, scope.last_pos
  else
    local tbl = scope:line_table()
    return result, tbl
  end
end
