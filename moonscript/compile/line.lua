module("moonscript.compile", package.seeall)
local util = require("moonscript.util")
local data = require("moonscript.data")
local dump = require("moonscript.dump")
require("moonscript.compile.format")
local reversed = util.reversed
local ntype = data.ntype
local concat, insert = table.concat, table.insert
local constructor_name = "new"
local is_slice
is_slice = function(node) return ntype(node) == "chain" and ntype(node[#node]) == "slice" end
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
  import = function(self, node)
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
  export = function(self, node)
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
  class = function(self, node)
    local _, name, parent_val, tbl = unpack(node)
    local constructor = nil
    local final_properties = {  }
    local find_special
    find_special = function(name, value)
      if name == constructor_name then
        constructor = value
      else
        return insert(final_properties, { name, value })
      end
    end
    local _item_0 = tbl[2]
    for _index_0=1,#_item_0 do
      local entry = _item_0[_index_0]
      find_special(unpack(entry))
    end
    tbl[2] = final_properties
    local def_scope = self:block()
    local parent_loc = def_scope:free_name("parent")
    def_scope:set("super", function(block, chain)
      local calling_name = block:get("current_block")
      local slice = (function()
        local _moon_0 = {}
        for i, item in ipairs(chain) do
          if i > 2 then
            table.insert(_moon_0, item)
          end
        end
        return _moon_0
      end)()
      slice[1] = { "call", { "self", unpack(slice[1][2]) } }
      return {
        "chain",
        parent_loc,
        { "dot", calling_name },
        unpack(slice)
      }
    end)
    if not constructor then
      constructor = {
        "fndef",
        { "..." },
        "fat",
        { { "if", parent_loc, { { "chain", "super", { "call", { "..." } } } } } }
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
    constructor[3] = "fat"
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
    local base_name = def_scope:free_name("base")
    def_scope:add_line(("local %s ="):format(base_name), def_scope:value(tbl))
    def_scope:add_line(("%s.__index = %s"):format(base_name, base_name))
    local cls = def_scope:value({ "table", { { "__init", constructor } } })
    local cls_mt = def_scope:value({ "table", { { "__index", base_name }, { "__call", {
            "fndef",
            { "mt", "..." },
            "slim",
            { { "raw", ("local self = setmetatable({}, %s)"):format(base_name) }, { "chain", "mt.__init", { "call", { "self", "..." } } }, "self" }
          } } } })
    if parent_val ~= "" then
      def_scope:stm({ "if", parent_loc, { { "chain", "setmetatable", { "call", { base_name, {
                  "chain",
                  "getmetatable",
                  { "call", { parent_loc } },
                  { "dot", "__index" }
                } } } } } })
    end
    def_scope:add_line(("return setmetatable(%s, %s)"):format(cls, cls_mt))
    if parent_val ~= "" then
      parent_val = self:value(parent_val)
    end
    local def = concat({ ("(function(%s)\n"):format(parent_loc), def_scope:render(), ("\nend)(%s)"):format(parent_val) })
    self:add_line("local", name)
    self:put_name(name)
    return self:stm({ "assign", { name }, { def } })
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
      action:set_indent(self.indent - 1)
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
          local items_tmp = action:free_name("item")
          local index_tmp = action:free_name("index")
          local max_tmp = nil
          insert(self._lines, 1, ("local %s = %s[%s]"):format(name_list, items_tmp, index_tmp))
          local min, max, skip = 1, ("#%s"):format(items_tmp, nil)
          if is_slice(iter) then
            local slice = iter[#iter]
            table.remove(iter)
            min = action:value(slice[2])
            if slice[3] and slice[3] ~= "" then
              max_tmp = action:free_name("max", true)
              action:stm({ "assign", { max_tmp }, { slice[3] } })
              max = action:value({
                "exp",
                max_tmp,
                "<",
                0,
                "and",
                {
                  "exp",
                  { "length", items_tmp },
                  "+",
                  max_tmp
                },
                "or",
                max_tmp
              })
            end
            if slice[4] then
              skip = action:value(slice[4])
            end
          end
          return action:add_lines({
            ("local %s = %s"):format(items_tmp, action:value(iter)),
            ("for %s=%s do"):format(index_tmp, concat({ min, max, skip }, ",")),
            self:render(true),
            "end"
          })
        else
          return action:add_lines({ ("for %s in %s do"):format(name_list, action:value(iter)), self:render(true), "end" })
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
  end,
  with = function(self, node, ret)
    local _, exp, block = unpack(node)
    local inner = self:block()
    local tmp_name = inner:free_name("with", true)
    self:set("scope_var", tmp_name)
    inner:stm({ "assign", { tmp_name }, { exp } })
    inner:stms(block)
    if ret then
      inner:stm(ret(tmp_name))
    end
    self:add_line("do")
    self:add_line(inner:render())
    return self:add_line("end")
  end
}
