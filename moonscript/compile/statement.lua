module("moonscript.compile", package.seeall)
local util = require("moonscript.util")
require("moonscript.compile.format")
local dump = require("moonscript.dump")
local transform = require("moonscript.transform")
local reversed = util.reversed
local ntype
do
  local _table_0 = require("moonscript.types")
  ntype = _table_0.ntype
end
local concat, insert = table.concat, table.insert
line_compile = {
  raw = function(self, node)
    return self:add(node[2])
  end,
  lines = function(self, node)
    local _list_0 = node[2]
    for _index_0 = 1, #_list_0 do
      local line = _list_0[_index_0]
      self:add(line)
    end
  end,
  declare = function(self, node)
    local names = node[2]
    local undeclared = self:declare(names)
    if #undeclared > 0 then
      do
        local _with_0 = self:line("local ")
        _with_0:append_list((function()
          local _accum_0 = { }
          local _len_0 = 0
          local _list_0 = undeclared
          for _index_0 = 1, #_list_0 do
            local name = _list_0[_index_0]
            _len_0 = _len_0 + 1
            _accum_0[_len_0] = self:name(name)
          end
          return _accum_0
        end)(), ", ")
        return _with_0
      end
    end
  end,
  declare_with_shadows = function(self, node)
    local names = node[2]
    self:declare(names)
    do
      local _with_0 = self:line("local ")
      _with_0:append_list((function()
        local _accum_0 = { }
        local _len_0 = 0
        local _list_0 = names
        for _index_0 = 1, #_list_0 do
          local name = _list_0[_index_0]
          _len_0 = _len_0 + 1
          _accum_0[_len_0] = self:name(name)
        end
        return _accum_0
      end)(), ", ")
      return _with_0
    end
  end,
  assign = function(self, node)
    local _, names, values = unpack(node)
    local undeclared = self:declare(names)
    local declare = "local " .. concat(undeclared, ", ")
    local has_fndef = false
    local i = 1
    while i <= #values do
      if ntype(values[i]) == "fndef" then
        has_fndef = true
      end
      i = i + 1
    end
    do
      local _with_0 = self:line()
      if #undeclared == #names and not has_fndef then
        _with_0:append(declare)
      else
        if #undeclared > 0 then
          self:add(declare)
        end
        _with_0:append_list((function()
          local _accum_0 = { }
          local _len_0 = 0
          local _list_0 = names
          for _index_0 = 1, #_list_0 do
            local name = _list_0[_index_0]
            _len_0 = _len_0 + 1
            _accum_0[_len_0] = self:value(name)
          end
          return _accum_0
        end)(), ", ")
      end
      _with_0:append(" = ")
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
      end)(), ", ")
      return _with_0
    end
  end,
  ["return"] = function(self, node)
    return self:line("return ", (function()
      if node[2] ~= "" then
        return self:value(node[2])
      end
    end)())
  end,
  ["break"] = function(self, node)
    return "break"
  end,
  ["if"] = function(self, node)
    local cond, block = node[2], node[3]
    local root
    do
      local _with_0 = self:block(self:line("if ", self:value(cond), " then"))
      _with_0:stms(block)
      root = _with_0
    end
    local current = root
    local add_clause
    add_clause = function(clause)
      local type = clause[1]
      local i = 2
      local next
      if type == "else" then
        next = self:block("else")
      else
        i = i + 1
        next = self:block(self:line("elseif ", self:value(clause[2]), " then"))
      end
      next:stms(clause[i])
      current.next = next
      current = next
    end
    local _list_0 = node
    for _index_0 = 4, #_list_0 do
      cond = _list_0[_index_0]
      add_clause(cond)
    end
    return root
  end,
  ["repeat"] = function(self, node)
    local cond, block = unpack(node, 2)
    do
      local _with_0 = self:block("repeat", self:line("until ", self:value(cond)))
      _with_0:stms(block)
      return _with_0
    end
  end,
  ["while"] = function(self, node)
    local _, cond, block = unpack(node)
    do
      local _with_0 = self:block(self:line("while ", self:value(cond), " do"))
      _with_0:stms(block)
      return _with_0
    end
  end,
  ["for"] = function(self, node)
    local _, name, bounds, block = unpack(node)
    local loop = self:line("for ", self:name(name), " = ", self:value({
      "explist",
      unpack(bounds)
    }), " do")
    do
      local _with_0 = self:block(loop)
      _with_0:declare({
        name
      })
      _with_0:stms(block)
      return _with_0
    end
  end,
  foreach = function(self, node)
    local _, names, exps, block = unpack(node)
    local loop
    do
      local _with_0 = self:line()
      _with_0:append("for ")
      _with_0:append_list((function()
        local _accum_0 = { }
        local _len_0 = 0
        local _list_0 = names
        for _index_0 = 1, #_list_0 do
          local name = _list_0[_index_0]
          _len_0 = _len_0 + 1
          _accum_0[_len_0] = self:name(name)
        end
        return _accum_0
      end)(), ", ")
      _with_0:append(" in ")
      _with_0:append_list((function()
        local _accum_0 = { }
        local _len_0 = 0
        local _list_0 = exps
        for _index_0 = 1, #_list_0 do
          local exp = _list_0[_index_0]
          _len_0 = _len_0 + 1
          _accum_0[_len_0] = self:value(exp)
        end
        return _accum_0
      end)(), ",")
      _with_0:append(" do")
      loop = _with_0
    end
    do
      local _with_0 = self:block(loop)
      _with_0:declare(names)
      _with_0:stms(block)
      return _with_0
    end
  end,
  export = function(self, node)
    local _, names = unpack(node)
    if type(names) == "string" then
      if names == "*" then
        self.export_all = true
      elseif names == "^" then
        self.export_proper = true
      end
    else
      self:declare(names)
    end
    return nil
  end,
  run = function(self, code)
    code:call(self)
    return nil
  end,
  group = function(self, node)
    return self:stms(node[2])
  end,
  ["do"] = function(self, node)
    do
      local _with_0 = self:block()
      _with_0:stms(node[2])
      return _with_0
    end
  end
}
