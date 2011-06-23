module("moonscript.compile", package.seeall)
local util = require("moonscript.util")
local data = require("moonscript.data")
local dump = require("moonscript.dump")
require("moonscript.compile.format")
require("moonscript.compile.line")
local map, bind, itwos, every, reversed = util.map, util.bind, util.itwos, util.every, util.reversed
local Stack, Set, ntype = data.Stack, data.Set, data.ntype
local concat, insert = table.concat, table.insert
local value_compile = {
  exp = function(self, node)
    local _comp
    _comp = function(i, value)
      if i % 2 == 1 and value == "!=" then
        value = "~="
      end
      return self:value(value)
    end
    return concat((function()
      local _moon_0 = {}
      for i, v in ipairs(node) do
        if i > 1 then
          table.insert(_moon_0, _comp(i, v))
        end
      end
      return _moon_0
    end)(), " ")
  end,
  update = function(self, node)
    local _, name = unpack(node)
    self:stm(node)
    return self:name(name)
  end,
  explist = function(self, node) return concat((function()
      local _moon_0 = {}
      local _item_0 = node
      for _index_0=2,#_item_0 do
        local v = _item_0[_index_0]
        table.insert(_moon_0, self:value(v))
      end
      return _moon_0
    end)(), ", ") end,
  parens = function(self, node) return "(" .. (self:value(node[2])) .. ")" end,
  string = function(self, node)
    local _, delim, inner, delim_end = unpack(node)
    return delim .. inner .. (delim_end or delim)
  end,
  ["if"] = function(self, node)
    local func = self:block()
    func:stm(node, returner)
    return self:format("(function()", func:render(), "end)()")
  end,
  comprehension = function(self, node)
    local exp = node[2]
    local func = self:block()
    local tmp_name = func:free_name()
    func:add_line("local", tmp_name, "= {}")
    local action = func:block()
    action:add_line(("table.insert(%s, %s)"):format(tmp_name, func:value(exp)))
    func:stm(node, action)
    func:add_line("return", tmp_name)
    return self:format("(function()", func:render(), "end)()")
  end,
  chain = function(self, node)
    local callee = node[2]
    if callee == -1 then
      callee = self:get("scope_var")
      if not callee then
        error("Short-dot syntax must be called within a with block")
      end
    end
    local sup = self:get("super")
    if callee == "super" and sup then
      return(self:value(sup(self, node)))
    end
    local chain_item
    chain_item = function(node)
      local t, arg = unpack(node)
      if t == "call" then
        return "(" .. (self:values(arg)) .. ")"
      elseif t == "index" then
        return "[" .. (self:value(arg)) .. "]"
      elseif t == "dot" then
        return "." .. arg
      elseif t == "colon" then
        return ":" .. arg .. (chain_item(node[3]))
      else
        return error("Unknown chain action: " .. t)
      end
    end
    local actions = (function()
      local _moon_0 = {}
      local _item_0 = node
      for _index_0=3,#_item_0 do
        local act = _item_0[_index_0]
        table.insert(_moon_0, chain_item(act))
      end
      return _moon_0
    end)()
    if ntype(callee) == "self" and node[3] and ntype(node[3]) == "call" then
      callee[1] = "self_colon"
    end
    local callee_value = self:name(callee)
    if ntype(callee) == "exp" then
      callee_value = "(" .. callee_value .. ")"
    end
    return self:name(callee) .. concat(actions)
  end,
  fndef = function(self, node)
    local _, args, arrow, block = unpack(node)
    if arrow == "fat" then
      insert(args, 1, "self")
    end
    local b = self:block()
    local _item_0 = args
    for _index_0=1,#_item_0 do
      local name = _item_0[_index_0]
      b:put_name(name)
    end
    b:ret_stms(block)
    local decl = "function(" .. (concat(args, ", ")) .. ")"
    if #b._lines == 0 then
      return decl .. " end"
    elseif #b._lines == 1 then
      return concat({ decl, b._lines[1], "end" }, " ")
    else
      return self:format(decl, b._lines, "end")
    end
  end,
  table = function(self, node)
    local _, items = unpack(node)
    local inner = self:block()
    local _comp
    _comp = function(i, tuple)
      local out
      if #tuple == 2 then
        local key, value = unpack(tuple)
        if type(key) == "string" and data.lua_keywords[key] then
          key = { "string", '"', key }
        end
        local key_val = self:value(key)
        if type(key) ~= "string" then
          key = ("[%s]"):format(key_val)
        else
          key = key_val
        end
        inner:set("current_block", key_val)
        value = inner:value(value)
        inner:set("current_block", nil)
        out = ("%s = %s"):format(key, value)
      else
        out = inner:value(tuple[1])
      end
      if i ~= #items then
        return out .. ","
      else
        return out
      end
    end
    local values = (function()
      local _moon_0 = {}
      for i, v in ipairs(items) do
        table.insert(_moon_0, _comp(i, v))
      end
      return _moon_0
    end)()
    if #values > 3 then
      return self:format("{", values, "}")
    else
      return "{ " .. (concat(values, " ")) .. " }"
    end
  end,
  minus = function(self, node) return "-" .. self:value(node[2]) end,
  length = function(self, node) return "#" .. self:value(node[2]) end,
  ["not"] = function(self, node) return "not " .. self:value(node[2]) end,
  self = function(self, node) return "self." .. self:value(node[2]) end,
  self_colon = function(self, node) return "self:" .. self:value(node[2]) end
}
local Block
Block = (function(_parent_0)
  local _base_0 = {
    set = function(self, name, value) self._state[name] = value end,
    get = function(self, name) return self._state[name] end,
    set_indent = function(self, depth)
      self.indent = depth
      self.lead = indent_char:rep(self.indent)
    end,
    declare = function(self, names)
      local undeclared = (function()
        local _moon_0 = {}
        local _item_0 = names
        for _index_0=1,#_item_0 do
          local name = _item_0[_index_0]
          if type(name) == "string" and not self:has_name(name) then
            table.insert(_moon_0, name)
          end
        end
        return _moon_0
      end)()
      local _item_0 = undeclared
      for _index_0=1,#_item_0 do
        local name = _item_0[_index_0]
        self:put_name(name)
      end
      return undeclared
    end,
    put_name = function(self, name) self._names[name] = true end,
    has_name = function(self, name) return self._names[name] end,
    free_name = function(self, prefix, dont_put)
      prefix = prefix or "moon"
      local searching = true
      local name, i = nil, 0
      while searching do
        name = concat({ "", prefix, i }, "_")
        i = i + 1
        searching = self:has_name(name)
      end
      if not dont_put then
        self:put_name(name)
      end
      return name
    end,
    add_lines = function(self, lines)
      local _item_0 = lines
      for _index_0=1,#_item_0 do
        local line = _item_0[_index_0]
        insert(self._lines, line)
      end
      return nil
    end,
    add_line = function(self, ...)
      local args = { ... }
      local line
      if #args == 1 then
        line = args[1]
      else
        line = concat(args, " ")
      end
      return insert(self._lines, line)
    end,
    push = function(self) self._names = setmetatable({  }, { __index = self._names }) end,
    pop = function(self) self._names = getmetatable(self._names).__index end,
    format = function(self, ...) return pretty({ ... }, self.lead) end,
    render = function(self)
      local out = pretty(self._lines, self.lead)
      if self.indent > 0 then
        out = indent_char .. out
      end
      return out
    end,
    block = function(self, node) return Block(self) end,
    is_stm = function(self, node) return line_compile[ntype(node)] ~= nil end,
    is_value = function(self, node)
      local t = ntype(node)
      return value_compile[t] ~= nil or t == "value"
    end,
    name = function(self, node) return self:value(node) end,
    value = function(self, node, ...)
      if type(node) ~= "table" then
        return(tostring(node))
      end
      local fn = value_compile[node[1]]
      if not fn then
        error("Failed to compile value: " .. dump.value(node))
      end
      return fn(self, node, ...)
    end,
    values = function(self, values, delim)
      delim = delim or ', '
      return concat((function()
        local _moon_0 = {}
        local _item_0 = values
        for _index_0=1,#_item_0 do
          local v = _item_0[_index_0]
          table.insert(_moon_0, self:value(v))
        end
        return _moon_0
      end)(), delim)
    end,
    stm = function(self, node, ...)
      local fn = line_compile[ntype(node)]
      if not fn then
        if has_value(node) then
          return self:stm({ "assign", { "_" }, { node } })
        else
          return self:add_line(self:value(node))
        end
      else
        local out = fn(self, node, ...)
        if out then
          return self:add_line(out)
        end
      end
    end,
    ret_stms = function(self, stms, ret)
      if not ret then
        ret = returner
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
        local _item_0 = stms
        for _index_0=1,#_item_0 do
          local stm = _item_0[_index_0]
          self:stm(stm)
        end
      end
      return nil
    end
  }
  _base_0.__index = _base_0
  return setmetatable({ __init = function(self, parent)
      self.parent = parent
      self:set_indent(self.parent and self.parent.indent + 1 or 0)
      self._lines = {  }
      self._names = {  }
      self._state = {  }
      if self.parent then
        setmetatable(self._state, { __index = self.parent._state })
        return setmetatable(self._names, { __index = self.parent._names })
      end
    end }, { __index = _base_0, __call = function(mt, ...)
      local self = setmetatable({}, _base_0)
      mt.__init(self, ...)
      return self
    end })
end)()
local build_compiler
build_compiler = function()
  Block(nil)
  return setmetatable({  }, { __index = compiler_index })
end
tree = function(tree)
  local scope = Block()
  local _item_0 = tree
  for _index_0=1,#_item_0 do
    local line = _item_0[_index_0]
    scope:stm(line)
  end
  return scope:render()
end
