module("moonscript.compile", package.seeall)
local util = require("moonscript.util")
require("moonscript.compile.format")
local dump = require("moonscript.dump")
local reversed = util.reversed
local ntype
do
  local _table_0 = require("moonscript.types")
  ntype = _table_0.ntype
end
local concat, insert = table.concat, table.insert
line_compile = {
  raw = function(self, node)
    local _, text = unpack(node)
    return self:add(text)
  end,
  declare = function(self, node)
    local _, names = unpack(node)
    local undeclared = self:declare(names)
    if #undeclared > 0 then
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
  ["while"] = function(self, node)
    local _, cond, block = unpack(node)
    local out
    if is_non_atomic(cond) then
      do
        local _with_0 = self:block("while true do")
        _with_0:stm({
          "if",
          {
            "not",
            cond
          },
          {
            {
              "break"
            }
          }
        })
        out = _with_0
      end
    else
      out = self:block(self:line("while ", self:value(cond), " do"))
    end
    out:stms(block)
    return out
  end,
  ["for"] = function(self, node)
    local _, name, bounds, block = unpack(node)
    local loop = self:line("for ", self:name(name), " = ", self:value({
      "explist",
      unpack(bounds)
    }), " do")
    do
      local _with_0 = self:block(loop)
      _with_0:stms(block)
      return _with_0
    end
  end,
  foreach = function(self, node)
    local _, names, exp, block = unpack(node)
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
      _with_0:append(" in ", self:value(exp), " do")
      loop = _with_0
    end
    do
      local _with_0 = self:block(loop)
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
