module("moonscript.compile", package.seeall)
local util = require("moonscript.util")
local data = require("moonscript.data")
local dump = require("moonscript.dump")
local map, bind, itwos, every, reversed = util.map, util.bind, util.itwos, util.every, util.reversed
local Stack, Set, ntype = data.Stack, data.Set, data.ntype
local concat, insert = table.concat, table.insert
local indent_char = "  "
local pretty
pretty = function(lines, indent)
  indent = indent or ""
  local render
  render = function(line)
    if type(line) == "table" then
      return indent_char .. pretty(line, indent .. indent_char)
    else
      return line
    end
  end
  lines = (function()
    local _moon_0 = {}
    local _item_0 = lines
    for _index_0=1,#_item_0 do
      local line = _item_0[_index_0]
      table.insert(_moon_0, render(line))
    end
    return _moon_0
  end)()
  local fix
  fix = function(i, left, k, right)
    if left:sub(-1) == ")" and right:sub(1, 1) == "(" then
      lines[i] = lines[i] .. ";"
    end
  end
  for i, l, k, r in itwos(lines) do
    fix(i, l, k, r)
  end
  return concat(lines, "\n" .. indent)
end
local returner
returner = function(exp)
  if ntype(exp) == "chain" and exp[2] == "return" then
    local items = { "explist" }
    local _item_0 = exp[3][2]
    for _index_0=1,#_item_0 do
      local v = _item_0[_index_0]
      insert(items, v)
    end
    return { "return", items }
  else
    return { "return", exp }
  end
end
local moonlib = { bind = function(tbl, name) return concat({
      "moon.bind(",
      tbl,
      ".",
      name,
      ", ",
      tbl,
      ")"
    }) end }
local cascading = Set({ "if" })
local has_value
has_value = function(node)
  if ntype(node) == "chain" then
    local ctype = ntype(node[#node])
    return ctype ~= "call" and ctype ~= "colon"
  else
    return true
  end
end
local line_compile = {
  assign = function(self, node)
    local _, names, values = unpack(node)
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
    local declare = "local " .. (concat(undeclared, ", "))
    if self:is_stm(values) then
      if #undeclared > 0 then
        self:add_line(declare)
      end
      if cascading[ntype(values)] then
        local decorate
        decorate = function(value) return { "assign", names, { value } } end
        return self:stm(values, decorate)
      else
        return self:add_line(concat((function()
          local _moon_0 = {}
          local _item_0 = names
          for _index_0=1,#_item_0 do
            local n = _item_0[_index_0]
            table.insert(_moon_0, self:value(n))
          end
          return _moon_0
        end)(), ", ") .. " = " .. self:value(values))
      end
    else
      local has_fndef = false
      local i = 1
      while i <= #values do
        if ntype(values[i]) == "fndef" then
          has_fndef = true
        end
        i = i + 1
      end
      values = concat((function()
        local _moon_0 = {}
        local _item_0 = values
        for _index_0=1,#_item_0 do
          local v = _item_0[_index_0]
          table.insert(_moon_0, self:value(v))
        end
        return _moon_0
      end)(), ", ")
      if #undeclared == #names and not has_fndef then
        return self:add_line(declare .. ' = ' .. values)
      else
        if #undeclared > 0 then
          self:add_line(declare)
        end
        return self:add_line(concat((function()
          local _moon_0 = {}
          local _item_0 = names
          for _index_0=1,#_item_0 do
            local n = _item_0[_index_0]
            table.insert(_moon_0, self:value(n))
          end
          return _moon_0
        end)(), ", ") .. " = " .. values)
      end
    end
  end,
  ["return"] = function(self, node) return self:add_line("return", self:value(node[2])) end,
  ["import"] = function(self, node)
    local _, names, source = unpack(node)
    local to_bind = {  }
    local get_name
    get_name = function(name)
      if ntype(name) == ":" then
        local tmp = self:name(name[2])
        to_bind[tmp] = true
        return tmp
      else
        return self:name(name)
      end
    end
    local final_names = (function()
      local _moon_0 = {}
      local _item_0 = names
      for _index_0=1,#_item_0 do
        local n = _item_0[_index_0]
        table.insert(_moon_0, get_name(n))
      end
      return _moon_0
    end)()
    local _item_0 = final_names
    for _index_0=1,#_item_0 do
      local name = _item_0[_index_0]
      self:put_name(name)
    end
    local get_value
    get_value = function(name)
      if to_bind[name] then
        return moonlib.bind(source, name)
      else
        return source .. "." .. name
      end
    end
    if type(source) == "string" then
      local values = (function()
        local _moon_0 = {}
        local _item_0 = final_names
        for _index_0=1,#_item_0 do
          local name = _item_0[_index_0]
          table.insert(_moon_0, get_value(name))
        end
        return _moon_0
      end)()
      self:add_line("local", (concat(final_names, ", ")), "=", (concat(values, ", ")))
      return(nil)
    end
    self:add_line("local", concat(final_names, ", "))
    self:add_line("do")
    local inner = self:block()
    local tmp_name = inner:free_name("table")
    inner:add_line("local", tmp_name, "=", self:value(source))
    source = tmp_name
    local _item_0 = final_names
    for _index_0=1,#_item_0 do
      local name = _item_0[_index_0]
      inner:add_line(name .. " = " .. get_value(name))
    end
    self:add_line(inner:render())
    return self:add_line("end")
  end,
  ["if"] = function(self, node, ret)
    local cond, block = node[2], node[3]
    local add_clause
    add_clause = function(clause)
      local type = clause[1]
      if type == "else" then
        self:add_line("else")
        block = clause[2]
      else
        self:add_line("elseif", (self:value(clause[2])), "then")
        block = clause[3]
      end
      local b = self:block()
      b:stms(block, ret)
      return self:add_line(b:render())
    end
    self:add_line("if", (self:value(cond)), "then")
    local b = self:block()
    b:stms(block, ret)
    self:add_line(b:render())
    for i, cond in ipairs(node) do
      if i > 3 then
        add_clause(cond)
      end
    end
    return self:add_line("end")
  end,
  ["while"] = function(self, node)
    local _, cond, block = unpack(node)
    self:add_line("while", self:value(cond), "do")
    local inner = self:block()
    inner:stms(block)
    self:add_line(inner:render())
    return self:add_line("end")
  end,
  comprehension = function(self, node, action)
    local _, exp, clauses = unpack(node)
    if not action then
      action = self:block()
      action:stm(exp)
    end
    local depth = #clauses
    action:set_indent(self.indent + depth)
    local render_clause
    render_clause = function(self, clause)
      local t = clause[1]
      action = self:block()
      action:set_indent(-1 + self.indent)
      if "for" == t then
        local names, iter
        _, names, iter = unpack(clause)
        local name_list = concat((function()
          local _moon_0 = {}
          local _item_0 = names
          for _index_0=1,#_item_0 do
            local name = _item_0[_index_0]
            table.insert(_moon_0, self:name(name))
          end
          return _moon_0
        end)(), ", ")
        if ntype(iter) == "unpack" then
          iter = iter[2]
          local items_tmp = self:free_name("item")
          local index_tmp = self:free_name("index")
          insert(self._lines, 1, ("local %s = %s[%s]"):format(name_list, items_tmp, index_tmp))
          return action:add_lines({
            ("local %s = %s"):format(items_tmp, self:value(iter)),
            ("for %s=1,#%s do"):format(index_tmp, items_tmp),
            self:render(true),
            "end"
          })
        else
          return action:add_lines({ ("for %s in %s do"):format(name_list, self:value(iter)), self:render(true), "end" })
        end
      elseif "when" == t then
        local cond
        _, cond = unpack(clause)
        return action:add_lines({ ("if %s then"):format(self:value(cond)), self:render(true), "end" })
      else
        return error("Unknown comprehension clause: " .. t)
      end
    end
    for i, clause in reversed(clauses) do
      render_clause(action, clause)
    end
    return self:add_lines(action._lines)
  end
}
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
  explist = function(self, node) return concat((function()
      local _moon_0 = {}
      for i, v in ipairs(node) do
        if i > 1 then
          table.insert(_moon_0, self:value(v))
        end
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
      for i, act in ipairs(node) do
        if i > 2 then
          table.insert(_moon_0, chain_item(act))
        end
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
        if type(key) ~= "string" then
          key = ("[%s]"):format(self:value(key))
        else
          key = self:value(key)
        end
        out = ("%s = %s"):format(key, inner:value(value))
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
local block_t = {  }
local Block
Block = function(parent)
  local indent = parent and parent.indent + 1 or 0
  local b = setmetatable({ _lines = {  }, _names = {  }, parent = parent }, block_t)
  b:set_indent(indent)
  return b
end
local B = {
  set_indent = function(self, depth)
    self.indent = depth
    self.lead = indent_char:rep(self.indent)
  end,
  put_name = function(self, name) self._names[name] = true end,
  has_name = function(self, name)
    if self._names[name] then
      return true
    elseif self.parent then
      return self.parent:has_name(name)
    else
      return false
    end
  end,
  free_name = function(self, prefix)
    prefix = prefix or "moon"
    local searching = true
    local name, i = nil, 0
    while searching do
      name = concat({ "", prefix, i }, "_")
      i = i + 1
      searching = self:has_name(name)
    end
    self:put_name(name)
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
block_t.__index = B
local build_compiler
build_compiler = function()
  Block(nil)
  return setmetatable({  }, { __index = compiler_index })
end
_M.tree = function(tree)
  local scope = Block()
  local _item_0 = tree
  for _index_0=1,#_item_0 do
    local line = _item_0[_index_0]
    scope:stm(line)
  end
  return scope:render()
end
