module("moonscript.compile", package.seeall)
local util = require("moonscript.util")
local data = require("moonscript.data")
local dump = require("moonscript.dump")
require("moonscript.compile.format")
require("moonscript.compile.types")
local reversed = util.reversed
local ntype = data.ntype
local concat, insert = table.concat, table.insert
local constructor_name = "new"
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
          do
            local _item_0 = names
            for _index_0 = 1, #_item_0 do
              local name = _item_0[_index_0]
              _len_0 = _len_0 + 1
              _accum_0[_len_0] = self:name(name)
            end
          end
          return _accum_0
        end)(), ", ")
        return _with_0
      end
    end
  end,
  assign = function(self, node)
    local _, names, values = unpack(node)
    if #values == 1 and cascading[ntype(values[1])] then
      return self:stm({
        "assign",
        names,
        values[1]
      })
    end
    local undeclared = self:declare(names)
    local declare = "local " .. concat(undeclared, ", ")
    if self:is_stm(values) then
      if #undeclared > 0 then
        self:add(declare)
      end
      if cascading[ntype(values)] then
        local decorate
        decorate = function(value)
          return {
            "assign",
            names,
            {
              value
            }
          }
        end
        return self:stm(values, decorate)
      else
        return error("Assigning unsupported statement")
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
            do
              local _item_0 = names
              for _index_0 = 1, #_item_0 do
                local name = _item_0[_index_0]
                _len_0 = _len_0 + 1
                _accum_0[_len_0] = self:value(name)
              end
            end
            return _accum_0
          end)(), ", ")
        end
        _with_0:append(" = ")
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
        end)(), ", ")
        return _with_0
      end
    end
  end,
  update = function(self, node)
    local _, name, op, exp = unpack(node)
    local op_final = op:match("(.)=")
    if not op_final then
      error("Unknown op: " .. op)
    end
    return self:stm({
      "assign",
      {
        name
      },
      {
        {
          "exp",
          name,
          op_final,
          exp
        }
      }
    })
  end,
  ["return"] = function(self, node)
    return self:line("return ", self:value(node[2]))
  end,
  ["break"] = function(self, node)
    return "break"
  end,
  import = function(self, node)
    local _, names, source = unpack(node)
    local final_names, to_bind = { }, { }
    do
      local _item_0 = names
      for _index_0 = 1, #_item_0 do
        local name = _item_0[_index_0]
        local final
        if ntype(name) == ":" then
          local tmp = self:name(name[2])
          to_bind[tmp] = true
          final = tmp
        else
          final = self:name(name)
        end
        self:put_name(final)
        insert(final_names, final)
      end
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
        local _accum_0 = { }
        local _len_0 = 0
        do
          local _item_0 = final_names
          for _index_0 = 1, #_item_0 do
            local name = _item_0[_index_0]
            _len_0 = _len_0 + 1
            _accum_0[_len_0] = get_value(name)
          end
        end
        return _accum_0
      end)()
      local line
      do
        local _with_0 = self:line("local ", concat(final_names, ", "), " = ")
        _with_0:append_list(values, ", ")
        line = _with_0
      end
      return line
    end
    self:add(self:line("local ", concat(final_names, ", ")))
    do
      local _with_0 = self:block("do")
      source = _with_0:init_free_var("table", source)
      do
        local _item_0 = final_names
        for _index_0 = 1, #_item_0 do
          local name = _item_0[_index_0]
          _with_0:stm({
            "assign",
            {
              name
            },
            {
              get_value(name)
            }
          })
        end
      end
      return _with_0
    end
  end,
  ["if"] = function(self, node, ret)
    local cond, block = node[2], node[3]
    local root
    do
      local _with_0 = self:block(self:line("if ", self:value(cond), " then"))
      _with_0:stms(block, ret)
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
      next:stms(clause[i], ret)
      current.next = next
      current = next
    end
    do
      local _item_0 = node
      for _index_0 = 4, #_item_0 do
        local cond = _item_0[_index_0]
        add_clause(cond)
      end
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
    if ntype(exp) == "unpack" then
      local iter = exp[2]
      local loop
      do
        local _with_0 = self:block()
        local items_tmp = _with_0:free_name("item", true)
        local bounds
        if is_slice(iter) then
          local slice = iter[#iter]
          table.remove(iter)
          table.remove(slice, 1)
          if slice[2] and slice[2] ~= "" then
            local max_tmp = _with_0:init_free_var("max", slice[2])
            slice[2] = {
              "exp",
              max_tmp,
              "<",
              0,
              "and",
              {
                "length",
                items_tmp
              },
              "+",
              max_tmp,
              "or",
              max_tmp
            }
          else
            slice[2] = {
              "length",
              items_tmp
            }
          end
          bounds = slice
        else
          bounds = {
            1,
            {
              "length",
              items_tmp
            }
          }
        end
        local index_tmp = _with_0:free_name("index")
        _with_0:stm({
          "assign",
          {
            items_tmp
          },
          {
            iter
          }
        })
        block = (function()
          local _accum_0 = { }
          local _len_0 = 0
          do
            local _item_0 = block
            for _index_0 = 1, #_item_0 do
              local s = _item_0[_index_0]
              _len_0 = _len_0 + 1
              _accum_0[_len_0] = s
            end
          end
          return _accum_0
        end)()
        do
          local _item_0 = names
          for _index_0 = 1, #_item_0 do
            local name = _item_0[_index_0]
            _with_0:shadow_name(name)
          end
        end
        insert(block, 1, {
          "assign",
          names,
          {
            {
              "chain",
              items_tmp,
              {
                "index",
                index_tmp
              }
            }
          }
        })
        _with_0:stm({
          "for",
          index_tmp,
          bounds,
          block
        })
        loop = _with_0
      end
      return loop
    end
    local loop
    do
      local _with_0 = self:line()
      _with_0:append("for ")
      _with_0:append_list((function()
        local _accum_0 = { }
        local _len_0 = 0
        do
          local _item_0 = names
          for _index_0 = 1, #_item_0 do
            local name = _item_0[_index_0]
            _len_0 = _len_0 + 1
            _accum_0[_len_0] = self:name(name)
          end
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
    self:declare(names)
    return nil
  end,
  class = function(self, node)
    local _, name, parent_val, tbl = unpack(node)
    local constructor = nil
    local final_properties = { }
    do
      local _item_0 = tbl[2]
      for _index_0 = 1, #_item_0 do
        local entry = _item_0[_index_0]
        if entry[1] == constructor_name then
          constructor = entry[2]
        else
          insert(final_properties, entry)
        end
      end
    end
    tbl[2] = final_properties
    local parent_loc = self:free_name("parent", true)
    if not constructor then
      constructor = {
        "fndef",
        {
          "..."
        },
        { },
        "fat",
        {
          {
            "if",
            parent_loc,
            {
              {
                "chain",
                "super",
                {
                  "call",
                  {
                    "..."
                  }
                }
              }
            }
          }
        }
      }
    end
    smart_node(constructor)
    local self_args = { }
    local get_initializers
    get_initializers = function(arg)
      if ntype(arg) == "self" then
        arg = arg[2]
        insert(self_args, arg)
      end
      return arg
    end
    constructor.args = (function()
      local _accum_0 = { }
      local _len_0 = 0
      do
        local _item_0 = constructor.args
        for _index_0 = 1, #_item_0 do
          local arg = _item_0[_index_0]
          _len_0 = _len_0 + 1
          _accum_0[_len_0] = get_initializers(arg)
        end
      end
      return _accum_0
    end)()
    constructor.arrow = "fat"
    local dests = (function()
      local _accum_0 = { }
      local _len_0 = 0
      do
        local _item_0 = self_args
        for _index_0 = 1, #_item_0 do
          local name = _item_0[_index_0]
          _len_0 = _len_0 + 1
          _accum_0[_len_0] = {
            "self",
            name
          }
        end
      end
      return _accum_0
    end)()
    if #self_args > 0 then
      insert(constructor.body, 1, {
        "assign",
        dests,
        self_args
      })
    end
    local def_scope
    do
      local _with_0 = self:block()
      if parent_val ~= "" then
        parent_val = self:value(parent_val)
      end
      _with_0:put_name(parent_loc)
      _with_0.header = self:line("(function(", parent_loc, ")")
      _with_0.footer = self:line("end)(", parent_val, ")")
      _with_0:set("super", function(block, chain)
        local calling_name = block:get("current_block")
        local slice = (function()
          local _accum_0 = { }
          local _len_0 = 0
          do
            local _item_0 = chain
            for _index_0 = 3, #_item_0 do
              local item = _item_0[_index_0]
              _len_0 = _len_0 + 1
              _accum_0[_len_0] = item
            end
          end
          return _accum_0
        end)()
        slice[1] = {
          "call",
          {
            "self",
            unpack(slice[1][2])
          }
        }
        local act
        if ntype(calling_name) ~= "value" then
          act = "index"
        else
          act = "dot"
        end
        return {
          "chain",
          parent_loc,
          {
            act,
            calling_name
          },
          unpack(slice)
        }
      end)
      local base_name = _with_0:init_free_var("base", tbl)
      _with_0:stm({
        "assign",
        {
          {
            "chain",
            base_name,
            {
              "dot",
              "__index"
            }
          }
        },
        {
          base_name
        }
      })
      _with_0:stm({
        "if",
        parent_loc,
        {
          {
            "chain",
            "setmetatable",
            {
              "call",
              {
                base_name,
                {
                  "chain",
                  "getmetatable",
                  {
                    "call",
                    {
                      parent_loc
                    }
                  },
                  {
                    "dot",
                    "__index"
                  }
                }
              }
            }
          }
        }
      })
      local cls = {
        "table",
        {
          {
            "__init",
            constructor
          }
        }
      }
      local cls_mt = {
        "table",
        {
          {
            "__index",
            base_name
          },
          {
            "__call",
            {
              "fndef",
              {
                "mt",
                "..."
              },
              { },
              "slim",
              {
                {
                  "raw",
                  ("local self = setmetatable({}, %s)"):format(base_name)
                },
                {
                  "chain",
                  "mt.__init",
                  {
                    "call",
                    {
                      "self",
                      "..."
                    }
                  }
                },
                "self"
              }
            }
          }
        }
      }
      local cls_name = _with_0:init_free_var("class", {
        "chain",
        "setmetatable",
        {
          "call",
          {
            cls,
            cls_mt
          }
        }
      })
      _with_0:stm({
        "assign",
        {
          {
            "chain",
            base_name,
            {
              "dot",
              "__class"
            }
          }
        },
        {
          cls_name
        }
      })
      _with_0:stm({
        "return",
        cls_name
      })
      def_scope = _with_0
    end
    self:stm({
      "declare",
      {
        name
      }
    })
    return self:line(name, " = ", def_scope)
  end,
  comprehension = function(self, node, action)
    local _, exp, clauses = unpack(node)
    if not action then
      action = function(exp)
        return {
          exp
        }
      end
    end
    local current_stms = action(exp)
    for _, clause in reversed(clauses) do
      local t = clause[1]
      if t == "for" then
        local names, iter
        _, names, iter = unpack(clause)
        current_stms = {
          "foreach",
          names,
          iter,
          current_stms
        }
      elseif t == "when" then
        local cond
        _, cond = unpack(clause)
        current_stms = {
          "if",
          cond,
          current_stms
        }
      else
        current_stms = error("Unknown comprehension clause: " .. t)
      end
      current_stms = {
        current_stms
      }
    end
    return self:stms(current_stms)
  end,
  with = function(self, node, ret)
    local _, exp, block = unpack(node)
    do
      local _with_0 = self:block()
      local var = _with_0:init_free_var("with", exp)
      self:set("scope_var", var)
      _with_0:stms(block)
      if ret then
        _with_0:stm(ret(var))
      end
      return _with_0
    end
  end
}
