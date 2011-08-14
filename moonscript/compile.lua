module("moonscript.compile", package.seeall)
local util = require("moonscript.util")
local data = require("moonscript.data")
local dump = require("moonscript.dump")
require("moonscript.compile.format")
require("moonscript.compile.line")
require("moonscript.compile.value")
local ntype, Set = data.ntype, data.Set
local concat, insert = table.concat, table.insert
local pos_to_line, get_closest_line, trim = util.pos_to_line, util.get_closest_line, util.trim
local bubble_names = {
  "has_varargs"
}
local Line
Line = (function(_parent_0)
  local _base_0 = {
    _append_single = function(self, item)
      if util.moon.type(item) == Line then
        do
          local _item_0 = item
          for _index_0 = 1, #_item_0 do
            local value = _item_0[_index_0]
            self:_append_single(value)
          end
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
      do
        local _item_0 = {
          ...
        }
        for _index_0 = 1, #_item_0 do
          local item = _item_0[_index_0]
          self:_append_single(item)
        end
      end
      return nil
    end,
    render = function(self)
      local buff = { }
      for i = 1, #self do
        local c = self[i]
        insert(buff, (function()
          if util.moon.type(c) == Block then
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
    setmetatable(_base_0, getmetatable(_parent_0).__index)
  end
  local _class_0 = setmetatable({
    __init = function(self, ...)
      if _parent_0 then
        return _parent_0.__init(self, ...)
      end
    end
  }, {
    __index = _base_0,
    __call = function(mt, ...)
      local self = setmetatable({}, _base_0)
      mt.__init(self, ...)
      return self
    end
  })
  _base_0.__class = _class_0
  return _class_0
end)()
local Block_
Block_ = (function(_parent_0)
  local _base_0 = {
    header = "do",
    footer = "end",
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
        do
          local _item_0 = names
          for _index_0 = 1, #_item_0 do
            local name = _item_0[_index_0]
            if type(name) == "string" and not self:has_name(name) then
              _len_0 = _len_0 + 1
              _accum_0[_len_0] = name
            end
          end
        end
        return _accum_0
      end)()
      do
        local _item_0 = undeclared
        for _index_0 = 1, #_item_0 do
          local name = _item_0[_index_0]
          self:put_name(name)
        end
      end
      return undeclared
    end,
    whitelist_names = function(self, names)
      self._name_whitelist = Set(names)
    end,
    put_name = function(self, name)
      self._names[name] = true
    end,
    has_name = function(self, name)
      local yes = self._names[name]
      if yes == nil and self.parent then
        if not self._name_whitelist or self._name_whitelist[name] then
          return self.parent:has_name(name)
        end
      else
        return yes
      end
    end,
    shadow_name = function(self, name)
      self._names[name] = false
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
        searching = self:has_name(name)
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
      do
        local _item_0 = line
        for _index_0 = 1, #_item_0 do
          local chunk = _item_0[_index_0]
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
      end
    end,
    add = function(self, line)
      local t = util.moon.type(line)
      if t == "string" then
        self:add_line_text(line)
      elseif t == Block then
        do
          local _item_0 = bubble_names
          for _index_0 = 1, #_item_0 do
            local name = _item_0[_index_0]
            if line[name] then
              self[name] = line.name
            end
          end
        end
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
          do
            local _item_0 = values
            for _index_0 = 1, #_item_0 do
              local v = _item_0[_index_0]
              _len_0 = _len_0 + 1
              _accum_0[_len_0] = self:value(v)
            end
          end
          return _accum_0
        end)(), delim)
        return _with_0
      end
    end,
    stm = function(self, node, ...)
      local fn = line_compile[ntype(node)]
      if not fn then
        if has_value(node) then
          return self:stm({
            "assign",
            {
              "_"
            },
            {
              node
            }
          })
        else
          return self:add(self:value(node))
        end
      else
        self:mark_pos(node)
        local out = fn(self, node, ...)
        if out then
          return self:add(out)
        end
      end
    end,
    ret_stms = function(self, stms, ret)
      if not ret then
        ret = default_return
      end
      local i = 1
      while i < #stms do
        self:stm(stms[i])
        i = i + 1
      end
      local last_exp = stms[i]
      if last_exp then
        if cascading[ntype(last_exp)] then
          self:stm(last_exp, ret)
        elseif self:is_value(last_exp) then
          local line = ret(stms[i])
          if self:is_stm(line) then
            self:stm(line)
          else
            error("got a value from implicit return")
          end
        else
          self:stm(last_exp)
        end
      end
      return nil
    end,
    stms = function(self, stms, ret)
      if ret then
        self:ret_stms(stms, ret)
      else
        do
          local _item_0 = stms
          for _index_0 = 1, #_item_0 do
            local stm = _item_0[_index_0]
            self:stm(stm)
          end
        end
      end
      return nil
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, getmetatable(_parent_0).__index)
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
        self.indent = self.parent.indent + 1
        return setmetatable(self._state, {
          __index = self.parent._state
        })
      else
        self.indent = 0
      end
    end
  }, {
    __index = _base_0,
    __call = function(mt, ...)
      local self = setmetatable({}, _base_0)
      mt.__init(self, ...)
      return self
    end
  })
  _base_0.__class = _class_0
  return _class_0
end)()
local RootBlock
RootBlock = (function(_parent_0)
  local _base_0 = {
    render = function(self)
      self:_insert_breaks()
      return concat(self._lines, "\n")
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, getmetatable(_parent_0).__index)
  end
  local _class_0 = setmetatable({
    __init = function(self, ...)
      if _parent_0 then
        return _parent_0.__init(self, ...)
      end
    end
  }, {
    __index = _base_0,
    __call = function(mt, ...)
      local self = setmetatable({}, _base_0)
      mt.__init(self, ...)
      return self
    end
  })
  _base_0.__class = _class_0
  return _class_0
end)(Block_)
Block = Block_
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
tree = function(tree)
  local scope = RootBlock()
  local runner = coroutine.create(function()
    do
      local _item_0 = tree
      for _index_0 = 1, #_item_0 do
        local line = _item_0[_index_0]
        scope:stm(line)
      end
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
