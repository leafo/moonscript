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
local pos_to_line, get_line, get_closest_line, trim = util.pos_to_line, util.get_line, util.get_closest_line, util.trim
local mtype = util.moon.type
local Line, Lines
Lines = (function()
  local _parent_0 = nil
  local _base_0 = {
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
    __tostring = function(self)
      local strip
      strip = function(t)
        if "table" == type(t) then
          return (function()
            local _accum_0 = { }
            local _len_0 = 0
            local _list_0 = t
            for _index_0 = 1, #_list_0 do
              local v = _list_0[_index_0]
              _len_0 = _len_0 + 1
              _accum_0[_len_0] = strip(v)
            end
            return _accum_0
          end)()
        else
          return t
        end
      end
      return "Lines<" .. tostring(util.dump(strip(self)):sub(1, -2)) .. ">"
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self)
      self.posmap = { }
    end,
    __base = _base_0,
    __name = "Lines",
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
  if _parent_0 and _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  return _class_0
end)()
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
    render = function(self, buffer)
      local current = { }
      local add_current
      add_current = function()
        return buffer:add(concat(current))
      end
      local _list_0 = self
      for _index_0 = 1, #_list_0 do
        local chunk = _list_0[_index_0]
        local _exp_0 = mtype(chunk)
        if Block == _exp_0 then
          local _list_1 = chunk:render(Lines())
          for _index_1 = 1, #_list_1 do
            local block_chunk = _list_1[_index_1]
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
  if _parent_0 and _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  return _class_0
end)()
Block = (function()
  local block_iterator
  local _parent_0 = nil
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
    line_table = function(self)
      return self._posmap
    end,
    set = function(self, name, value)
      self._state[name] = value
    end,
    get = function(self, name)
      return self._state[name]
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
    put_name = function(self, name, ...)
      value = ...
      if select("#", ...) == 0 then
        value = true
      end
      if util.moon.type(name) == NameProxy then
        name = name:get_name(self)
      end
      self._names[name] = value
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
    mark_pos = function(self, line_no, node)
      do
        local pos = node[-1]
        if pos then
          self.last_pos = pos
          if not (self._posmap[line_no]) then
            self._posmap[line_no] = pos
          end
        end
      end
    end,
    append_posmap = function(self, map)
      print("appending pos", self)
      self._posmap[#self._posmap + 1] = map
    end,
    add = function(self, item)
      self._lines:add(item)
      return item
    end,
    render = function(self, buffer)
      buffer:add(self.header)
      if self.next then
        buffer:add(self._lines)
        self.next:render(buffer)
      else
        if #self._lines == 0 and "string" == type(buffer[#buffer]) then
          buffer[#buffer] = buffer[#buffer] .. (" " .. (unpack(Lines():add(self.footer))))
        else
          buffer:add(self._lines)
          buffer:add(self.footer)
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
      node = self.transform.value(node)
      local action
      if type(node) ~= "table" then
        action = "raw_value"
      else
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
      node = self.transform.statement(node)
      local before = #self._lines
      local added
      do
        local fn = line_compile[ntype(node)]
        if fn then
          local out = fn(self, node, ...)
          if out then
            added = self:add(out)
          end
        else
          if has_value(node) then
            added = self:stm({
              "assign",
              {
                "_"
              },
              {
                node
              }
            })
          else
            added = self:add(self:value(node))
          end
        end
      end
      if added then
        print("added " .. tostring(#self._lines - before) .. " lines")
        local list
        if Line == mtype(added) then
          list = added
        else
          list = {
            added
          }
        end
        local next_block = block_iterator(list)
        for l = before + 1, #self._lines do
          if "table" == type(self._lines[l]) then
            local block = next_block()
            block._posmap.num_lines = #block._lines
            self._posmap[l] = block._posmap
          else
            self:mark_pos(l, node)
          end
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
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self, parent, header, footer)
      self.parent, self.header, self.footer = parent, header, footer
      self._lines = Lines()
      self._posmap = { }
      self._names = { }
      self._state = { }
      self._listeners = { }
      do
        local _with_0 = transform
        self.transform = {
          value = _with_0.Value:bind(self),
          statement = _with_0.Statement:bind(self)
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
  local self = _class_0
  block_iterator = function(list)
    return coroutine.wrap(function()
      local _list_0 = list
      for _index_0 = 1, #_list_0 do
        local item = _list_0[_index_0]
        if Block == mtype(item) then
          coroutine.yield(item)
        end
      end
    end)
  end
  if _parent_0 and _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  return _class_0
end)()
local flatten_lines
flatten_lines = function(lines, indent, buffer)
  if indent == nil then
    indent = nil
  end
  if buffer == nil then
    buffer = { }
  end
  for i = 1, #lines do
    local l = lines[i]
    local _exp_0 = type(l)
    if "string" == _exp_0 then
      if indent then
        insert(buffer, indent)
      end
      insert(buffer, l)
      if "string" == type(lines[i + 1]) then
        local lc = l:sub(-1)
        if (lc == ")" or lc == "]") and lines[i + 1]:sub(1, 1) == "(" then
          insert(buffer, ";")
        end
      end
      insert(buffer, "\n")
      local last = l
    elseif "table" == _exp_0 then
      flatten_lines(l, indent and indent .. indent_char or indent_char, buffer)
    end
  end
  return buffer
end
local flatten_posmap
flatten_posmap = function(posmap, dl, out)
  if dl == nil then
    dl = 0
  end
  if out == nil then
    out = { }
  end
  for k, v in pairs(posmap) do
    local _continue_0 = false
    repeat
      if "string" == type(k) then
        _continue_0 = true
        break
      end
      if "table" == type(v) then
        flatten_posmap(v, k - 1 + dl, out)
        dl = dl + (v.num_lines - 1)
      else
        out[k + dl] = v
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  return out
end
local debug_posmap
debug_posmap = function(posmap, fname, lua_code)
  if fname == nil then
    fname = error("pass in input file")
  end
  local moon_code = io.open(fname):read("*a")
  local tuples = (function()
    local _accum_0 = { }
    local _len_0 = 0
    for k, v in pairs(posmap) do
      _len_0 = _len_0 + 1
      _accum_0[_len_0] = {
        k,
        v
      }
    end
    return _accum_0
  end)()
  table.sort(tuples, function(a, b)
    return a[1] < b[1]
  end)
  local lines = (function()
    local _accum_0 = { }
    local _len_0 = 0
    local _list_0 = tuples
    for _index_0 = 1, #_list_0 do
      local pair = _list_0[_index_0]
      local lua_line, pos = unpack(pair)
      local moon_line = pos_to_line(moon_code, pos)
      local lua_text = get_line(lua_code, lua_line)
      local moon_text = get_closest_line(moon_code, moon_line)
      local _value_0 = tostring(pos) .. "\t " .. tostring(lua_line) .. ":[ " .. tostring(trim(lua_text)) .. " ] >> " .. tostring(moon_line) .. ":[ " .. tostring(trim(moon_text)) .. " ]"
      if _value_0 ~= nil then
        _len_0 = _len_0 + 1
        _accum_0[_len_0] = _value_0
      end
    end
    return _accum_0
  end)()
  return concat(lines, "\n") .. "\n"
end
RootBlock = (function()
  local _parent_0 = Block
  local _base_0 = {
    __tostring = function(self)
      return "RootBlock<>"
    end,
    render = function(self)
      local buffer = flatten_lines(self._lines)
      if buffer[#buffer] == "\n" then
        buffer[#buffer] = nil
      end
      return table.concat(buffer)
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self, ...)
      self.root = self
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
  if _parent_0 and _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
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
tree = function(tree, scope)
  if scope == nil then
    scope = RootBlock()
  end
  assert(tree, "missing tree")
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
    local raw_posmap = scope:line_table()
    local posmap = flatten_posmap(raw_posmap)
    print(util.dump(raw_posmap))
    print(util.dump(posmap))
    print(debug_posmap(posmap, "scrap.moon", result))
    return result, posmap
  end
end
