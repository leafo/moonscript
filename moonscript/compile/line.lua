module("moonscript.compile", package.seeall)
local util = require("moonscript.util")
local data = require("moonscript.data")
local dump = require("moonscript.dump")
require("moonscript.compile.format")
local reversed = util.reversed
local ntype = data.ntype
local concat, insert = table.concat, table.insert
local constructor_name = "new"
line_compile = {
  raw = function(self, node)
    local _, text = unpack(node)
    return self:add_line(text)
  end,
  assign = function(self, node)
    local _, names, values = unpack(node)
    local undeclared = self:declare(names)
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
  update = function(self, node)
    local _, name, op, exp = unpack(node)
    local op_final = op:match("(.)=")
    if not op_final then
      _ = error("unknown op: ") .. op
    end
    return self:stm({ "assign", { name }, { {
          "exp",
          name,
          op_final,
          exp
        } } })
  end,
  ["return"] = function(self, node) return self:add_line("return", self:value(node[2])) end,
  ["break"] = function(self, node) return self:add_line("break") end,
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
    local inner = self:block()
    if is_non_atomic(cond) then
      self:add_line("while", "true", "do")
      inner:stm({ "if", { "not", cond }, { { "break" } } })
    else
      self:add_line("while", self:value(cond), "do")
    end
    inner:stms(block)
    self:add_line(inner:render())
    return self:add_line("end")
  end,
  ["for"] = function(self, node)
    local _, name, bounds, block = unpack(node)
    bounds = self:value({ "explist", unpack(bounds) })
    self:add_line("for", self:name(name), "=", bounds, "do")
    local inner = self:block()
    inner:stms(block)
    self:add_line(inner:render())
    return self:add_line("end")
  end,
  ["export"] = function(self, node)
    local _, names = unpack(node)
    local _item_0 = names
    for _index_0=1,#_item_0 do
      local name = _item_0[_index_0]
      if type(name) == "string" then
        self:put_name(name)
      end
    end
    return nil
  end,
  ["class"] = function(self, node)
    local _, name, tbl = unpack(node)
    local mt_name = "_" .. name .. "_mt"
    self:add_line("local", concat(self:declare({ name, mt_name }), ", "))
    local constructor = nil
    local meta_methods = {  }
    local final_properties = {  }
    local overloaded_index = value
    local find_special
    find_special = function(name, value)
      if name == constructor_name then
        constructor = value
      elseif name:match("^__%a") then
        insert(meta_methods, { name, value })
        if name == "__index" then
          overloaded_index = value
        end
      else
        return insert(final_properties, { name, value })
      end
    end
    local _item_0 = tbl[2]
    for _index_0=1,#_item_0 do
      local entry = _item_0[_index_0]
      find_special(unpack(entry))
    end
    if not overloaded_index then
      insert(meta_methods, { "__index", { "table", final_properties } })
    end
    self:stm({ "assign", { mt_name }, { { "table", meta_methods } } })
    if not constructor then
      constructor = {
        "fndef",
        {  },
        "slim",
        {  }
      }
    end
    local self_args = {  }
    local get_initializers
    get_initializers = function(arg)
      if ntype(arg) == "self" then
        arg = arg[2]
        insert(self_args, arg)
      end
      return arg
    end
    constructor[2] = (function()
      local _moon_0 = {}
      local _item_0 = constructor[2]
      for _index_0=1,#_item_0 do
        local arg = _item_0[_index_0]
        table.insert(_moon_0, get_initializers(arg))
      end
      return _moon_0
    end)()
    constructor[3] = "slim"
    local body = constructor[4]
    local dests = (function()
      local _moon_0 = {}
      local _item_0 = self_args
      for _index_0=1,#_item_0 do
        local name = _item_0[_index_0]
        table.insert(_moon_0, { "self", name })
      end
      return _moon_0
    end)()
    if #self_args > 0 then
      insert(body, 1, { "assign", dests, self_args })
    end
    insert(body, 1, { "raw", ("local self = setmetatable({}, %s)"):format(mt_name) })
    insert(body, { "return", "self" })
    return self:stm({ "assign", { name }, { constructor } })
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
