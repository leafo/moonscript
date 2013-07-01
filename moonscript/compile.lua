local util = require("moonscript.util")
local dump = require("moonscript.dump")
local transform = require("moonscript.transform")
local NameProxy, LocalName
do
  local _obj_0 = require("moonscript.transform.names")
  NameProxy, LocalName = _obj_0.NameProxy, _obj_0.LocalName
end
local Set
do
  local _obj_0 = require("moonscript.data")
  Set = _obj_0.Set
end
local ntype, has_value
do
  local _obj_0 = require("moonscript.types")
  ntype, has_value = _obj_0.ntype, _obj_0.has_value
end
local statement_compilers
do
  local _obj_0 = require("moonscript.compile.statement")
  statement_compilers = _obj_0.statement_compilers
end
local value_compilers
do
  local _obj_0 = require("moonscript.compile.value")
  value_compilers = _obj_0.value_compilers
end
local concat, insert
do
  local _obj_0 = table
  concat, insert = _obj_0.concat, _obj_0.insert
end
local pos_to_line, get_closest_line, trim, unpack
pos_to_line, get_closest_line, trim, unpack = util.pos_to_line, util.get_closest_line, util.trim, util.unpack
local mtype = util.moon.type
local indent_char = "  "
local Line, DelayedLine, Lines, Block, RootBlock
do
  local _base_0 = {
    mark_pos = function(self, pos, line)
      if line == nil then
        line = #self
      end
      if not (self.posmap[line]) then
        self.posmap[line] = pos
      end
    end,
    add = function(self, item)
      local _exp_0 = mtype(item)
      if Line == _exp_0 then
        item:render(self)
      elseif Block == _exp_0 then
        item:render(self)
      else
        self[#self + 1] = item
      end
      return self
    end,
    flatten_posmap = function(self, line_no, out)
      if line_no == nil then
        line_no = 0
      end
      if out == nil then
        out = { }
      end
      local posmap = self.posmap
      for i, l in ipairs(self) do
        local _exp_0 = mtype(l)
        if "string" == _exp_0 or DelayedLine == _exp_0 then
          line_no = line_no + 1
          out[line_no] = posmap[i]
        elseif Lines == _exp_0 then
          local _
          _, line_no = l:flatten_posmap(line_no, out)
        else
          error("Unknown item in Lines: " .. tostring(l))
        end
      end
      return out, line_no
    end,
    flatten = function(self, indent, buffer)
      if indent == nil then
        indent = nil
      end
      if buffer == nil then
        buffer = { }
      end
      for i = 1, #self do
        local l = self[i]
        local t = mtype(l)
        if t == DelayedLine then
          l = l:render()
          t = "string"
        end
        local _exp_0 = t
        if "string" == _exp_0 then
          if indent then
            insert(buffer, indent)
          end
          insert(buffer, l)
          if "string" == type(self[i + 1]) then
            local lc = l:sub(-1)
            if (lc == ")" or lc == "]") and self[i + 1]:sub(1, 1) == "(" then
              insert(buffer, ";")
            end
          end
          insert(buffer, "\n")
          local last = l
        elseif Lines == _exp_0 then
          l:flatten(indent and indent .. indent_char or indent_char, buffer)
        else
          error("Unknown item in Lines: " .. tostring(l))
        end
      end
      return buffer
    end,
    __tostring = function(self)
      local strip
      strip = function(t)
        if "table" == type(t) then
          local _accum_0 = { }
          local _len_0 = 1
          for _index_0 = 1, #t do
            local v = t[_index_0]
            _accum_0[_len_0] = strip(v)
            _len_0 = _len_0 + 1
          end
          return _accum_0
        else
          return t
        end
      end
      return "Lines<" .. tostring(util.dump(strip(self)):sub(1, -2)) .. ">"
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.posmap = { }
    end,
    __base = _base_0,
    __name = "Lines"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Lines = _class_0
end
do
  local _base_0 = {
    pos = nil,
    _append_single = function(self, item)
      if Line == mtype(item) then
        if not (self.pos) then
          self.pos = item.pos
        end
        for _index_0 = 1, #item do
          local value = item[_index_0]
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
      return nil
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
    render = function(self, buffer)
      local current = { }
      local add_current
      add_current = function()
        buffer:add(concat(current))
        return buffer:mark_pos(self.pos)
      end
      for _index_0 = 1, #self do
        local chunk = self[_index_0]
        local _exp_0 = mtype(chunk)
        if Block == _exp_0 then
          local _list_0 = chunk:render(Lines())
          for _index_1 = 1, #_list_0 do
            local block_chunk = _list_0[_index_1]
            if "string" == type(block_chunk) then
              insert(current, block_chunk)
            else
              add_current()
              buffer:add(block_chunk)
              current = { }
            end
          end
        else
          insert(current, chunk)
        end
      end
      if #current > 0 then
        add_current()
      end
      return buffer
    end,
    __tostring = function(self)
      return "Line<" .. tostring(util.dump(self):sub(1, -2)) .. ">"
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Line"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Line = _class_0
end
do
  local _base_0 = {
    prepare = function() end,
    render = function(self)
      self:prepare()
      return concat(self)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, fn)
      self.prepare = fn
    end,
    __base = _base_0,
    __name = "DelayedLine"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  DelayedLine = _class_0
end
do
  local _base_0 = {
    header = "do",
    footer = "end",
    export_all = false,
    export_proper = false,
    __tostring = function(self)
      local h
      if "string" == type(self.header) then
        h = self.header
      else
        h = unpack(self.header:render({ }))
      end
      return "Block<" .. tostring(h) .. "> <- " .. tostring(self.parent)
    end,
    set = function(self, name, value)
      self._state[name] = value
    end,
    get = function(self, name)
      return self._state[name]
    end,
    get_current = function(self, name)
      return rawget(self._state, name)
    end,
    listen = function(self, name, fn)
      self._listeners[name] = fn
    end,
    unlisten = function(self, name)
      self._listeners[name] = nil
    end,
    send = function(self, name, ...)
      do
        local fn = self._listeners[name]
        if fn then
          return fn(self, ...)
        end
      end
    end,
    declare = function(self, names)
      local undeclared
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #names do
          local _continue_0 = false
          repeat
            local name = names[_index_0]
            local is_local = false
            local real_name
            local _exp_0 = mtype(name)
            if LocalName == _exp_0 then
              is_local = true
              real_name = name:get_name(self)
            elseif NameProxy == _exp_0 then
              real_name = name:get_name(self)
            elseif "string" == _exp_0 then
              real_name = name
            end
            if not (is_local or real_name and not self:has_name(real_name, true)) then
              _continue_0 = true
              break
            end
            self:put_name(real_name)
            if self:name_exported(real_name) then
              _continue_0 = true
              break
            end
            local _value_0 = real_name
            _accum_0[_len_0] = _value_0
            _len_0 = _len_0 + 1
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
        undeclared = _accum_0
      end
      return undeclared
    end,
    whitelist_names = function(self, names)
      self._name_whitelist = Set(names)
    end,
    name_exported = function(self, name)
      if self.export_all then
        return true
      end
      if self.export_proper and name:match("^%u") then
        return true
      end
    end,
    put_name = function(self, name, ...)
      local value = ...
      if select("#", ...) == 0 then
        value = true
      end
      if NameProxy == mtype(name) then
        name = name:get_name(self)
      end
      self._names[name] = value
    end,
    has_name = function(self, name, skip_exports)
      if not skip_exports and self:name_exported(name) then
        return true
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
    is_local = function(self, node)
      local t = mtype(node)
      if t == "string" then
        return self:has_name(node, false)
      end
      if t == NameProxy or t == LocalName then
        return true
      end
      if t == "table" and node[1] == "chain" and #node == 2 then
        return self:is_local(node[2])
      end
      return false
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
    add = function(self, item)
      self._lines:add(item)
      return item
    end,
    render = function(self, buffer)
      buffer:add(self.header)
      buffer:mark_pos(self.pos)
      if self.next then
        buffer:add(self._lines)
        self.next:render(buffer)
      else
        if #self._lines == 0 and "string" == type(buffer[#buffer]) then
          buffer[#buffer] = buffer[#buffer] .. (" " .. (unpack(Lines():add(self.footer))))
        else
          buffer:add(self._lines)
          buffer:add(self.footer)
          buffer:mark_pos(self.pos)
        end
      end
      return buffer
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
      return statement_compilers[ntype(node)] ~= nil
    end,
    is_value = function(self, node)
      local t = ntype(node)
      return value_compilers[t] ~= nil or t == "value"
    end,
    name = function(self, node, ...)
      return self:value(node, ...)
    end,
    value = function(self, node, ...)
      node = self.transform.value(node)
      local action
      if type(node) ~= "table" then
        action = "raw_value"
      else
        action = node[1]
      end
      local fn = value_compilers[action]
      if not fn then
        error("Failed to compile value: " .. dump.value(node))
      end
      local out = fn(self, node, ...)
      if type(node) == "table" and node[-1] then
        if type(out) == "string" then
          do
            local _with_0 = Line()
            _with_0:append(out)
            out = _with_0
          end
        end
        out.pos = node[-1]
      end
      return out
    end,
    values = function(self, values, delim)
      delim = delim or ', '
      do
        local _with_0 = Line()
        _with_0:append_list((function()
          local _accum_0 = { }
          local _len_0 = 1
          for _index_0 = 1, #values do
            local v = values[_index_0]
            _accum_0[_len_0] = self:value(v)
            _len_0 = _len_0 + 1
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
      node = self.transform.statement(node)
      local result
      do
        local fn = statement_compilers[ntype(node)]
        if fn then
          result = fn(self, node, ...)
        else
          if has_value(node) then
            result = self:stm({
              "assign",
              {
                "_"
              },
              {
                node
              }
            })
          else
            result = self:value(node)
          end
        end
      end
      if result then
        if type(node) == "table" and type(result) == "table" and node[-1] then
          result.pos = node[-1]
        end
        self:add(result)
      end
      return nil
    end,
    stms = function(self, stms, ret)
      if ret then
        error("deprecated stms call, use transformer")
      end
      local current_stms, current_stm_i
      current_stms, current_stm_i = self.current_stms, self.current_stm_i
      self.current_stms = stms
      for i = 1, #stms do
        self.current_stm_i = i
        self:stm(stms[i])
      end
      self.current_stms = current_stms
      self.current_stm_i = current_stm_i
      return nil
    end,
    splice = function(self, fn)
      local lines = {
        "lines",
        self._lines
      }
      self._lines = Lines()
      return self:stms(fn(lines))
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, parent, header, footer)
      self.parent, self.header, self.footer = parent, header, footer
      self._lines = Lines()
      self._names = { }
      self._state = { }
      self._listeners = { }
      do
        self.transform = {
          value = transform.Value:bind(self),
          statement = transform.Statement:bind(self)
        }
      end
      if self.parent then
        self.root = self.parent.root
        self.indent = self.parent.indent + 1
        setmetatable(self._state, {
          __index = self.parent._state
        })
        return setmetatable(self._listeners, {
          __index = self.parent._listeners
        })
      else
        self.indent = 0
      end
    end,
    __base = _base_0,
    __name = "Block"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Block = _class_0
end
do
  local _parent_0 = Block
  local _base_0 = {
    __tostring = function(self)
      return "RootBlock<>"
    end,
    root_stms = function(self, stms)
      if not (self.options.implicitly_return_root == false) then
        stms = transform.Statement.transformers.root_stms(self, stms)
      end
      return self:stms(stms)
    end,
    render = function(self)
      local buffer = self._lines:flatten()
      if buffer[#buffer] == "\n" then
        buffer[#buffer] = nil
      end
      return table.concat(buffer)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, options)
      self.options = options
      self.root = self
      return _parent_0.__init(self)
    end,
    __base = _base_0,
    __name = "RootBlock",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
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
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  RootBlock = _class_0
end
local format_error
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
local value
value = function(value)
  local out = nil
  do
    local _with_0 = RootBlock()
    _with_0:add(_with_0:value(value))
    out = _with_0:render()
  end
  return out
end
local tree
tree = function(tree, options)
  if options == nil then
    options = { }
  end
  assert(tree, "missing tree")
  local scope = (options.scope or RootBlock)(options)
  local runner = coroutine.create(function()
    return scope:root_stms(tree)
  end)
  local success, err = coroutine.resume(runner)
  if not success then
    local error_msg
    if type(err) == "table" then
      local error_type = err[1]
      if error_type == "user-error" then
        error_msg = err[2]
      else
        error_msg = error("Unknown error thrown", util.dump(error_msg))
      end
    else
      error_msg = concat({
        err,
        debug.traceback(runner)
      }, "\n")
    end
    return nil, error_msg, scope.last_pos
  else
    local lua_code = scope:render()
    local posmap = scope._lines:flatten_posmap()
    return lua_code, posmap
  end
end
do
  local data = require("moonscript.data")
  for name, cls in pairs({
    Line = Line,
    Lines = Lines,
    DelayedLine = DelayedLine
  }) do
    data[name] = cls
  end
end
return {
  tree = tree,
  value = value,
  format_error = format_error,
  Block = Block,
  RootBlock = RootBlock
}
