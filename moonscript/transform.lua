module("moonscript.transform", package.seeall)
local types = require("moonscript.types")
local util = require("moonscript.util")
local data = require("moonscript.data")
local reversed = util.reversed
local ntype, build, smart_node, is_slice, value_is_singular = types.ntype, types.build, types.smart_node, types.is_slice, types.value_is_singular
local insert = table.insert
local mtype = util.moon.type
local implicitly_return
do
  local _parent_0 = nil
  local _base_0 = {
    get_name = function(self)
      return self.name
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self, name)
      self.name = name
      self[1] = "temp_name"
    end,
    __base = _base_0,
    __name = "LocalName",
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
  LocalName = _class_0
end
do
  local _parent_0 = nil
  local _base_0 = {
    get_name = function(self, scope)
      if not self.name then
        self.name = scope:free_name(self.prefix, true)
      end
      return self.name
    end,
    chain = function(self, ...)
      local items = {
        ...
      }
      items = (function()
        local _accum_0 = { }
        local _len_0 = 0
        local _list_0 = items
        for _index_0 = 1, #_list_0 do
          local i = _list_0[_index_0]
          local _value_0
          if type(i) == "string" then
            _value_0 = {
              "dot",
              i
            }
          else
            _value_0 = i
          end
          if _value_0 ~= nil then
            _len_0 = _len_0 + 1
            _accum_0[_len_0] = _value_0
          end
        end
        return _accum_0
      end)()
      return build.chain({
        base = self,
        unpack(items)
      })
    end,
    index = function(self, key)
      return build.chain({
        base = self,
        {
          "index",
          key
        }
      })
    end,
    __tostring = function(self)
      if self.name then
        return ("name<%s>"):format(self.name)
      else
        return ("name<prefix(%s)>"):format(self.prefix)
      end
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self, prefix)
      self.prefix = prefix
      self[1] = "temp_name"
    end,
    __base = _base_0,
    __name = "NameProxy",
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
  NameProxy = _class_0
end
do
  local _parent_0 = nil
  local _base_0 = {
    call = function(self, state)
      return self.fn(state)
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self, fn)
      self.fn = fn
      self[1] = "run"
    end,
    __base = _base_0,
    __name = "Run",
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
  Run = _class_0
end
local apply_to_last
apply_to_last = function(stms, fn)
  local last_exp_id = 0
  for i = #stms, 1, -1 do
    local stm = stms[i]
    if stm and util.moon.type(stm) ~= Run then
      last_exp_id = i
      break
    end
  end
  return (function()
    local _accum_0 = { }
    local _len_0 = 0
    for i, stm in ipairs(stms) do
      local _value_0
      if i == last_exp_id then
        _value_0 = fn(stm)
      else
        _value_0 = stm
      end
      if _value_0 ~= nil then
        _len_0 = _len_0 + 1
        _accum_0[_len_0] = _value_0
      end
    end
    return _accum_0
  end)()
end
local is_singular
is_singular = function(body)
  if #body ~= 1 then
    return false
  end
  if "group" == ntype(body) then
    return is_singular(body[2])
  else
    return true
  end
end
local find_assigns
find_assigns = function(body, out)
  if out == nil then
    out = { }
  end
  local _list_0 = body
  for _index_0 = 1, #_list_0 do
    local thing = _list_0[_index_0]
    local _exp_0 = thing[1]
    if "group" == _exp_0 then
      find_assigns(thing[2], out)
    elseif "assign" == _exp_0 then
      table.insert(out, thing[2])
    end
  end
  return out
end
local hoist_declarations
hoist_declarations = function(body)
  local assigns = { }
  local _list_0 = find_assigns(body)
  for _index_0 = 1, #_list_0 do
    local names = _list_0[_index_0]
    local _list_1 = names
    for _index_1 = 1, #_list_1 do
      local name = _list_1[_index_1]
      if type(name) == "string" then
        table.insert(assigns, name)
      end
    end
  end
  local idx = 1
  while mtype(body[idx]) == Run do
    idx = idx + 1
  end
  return table.insert(body, idx, {
    "declare",
    assigns
  })
end
local expand_elseif_assign
expand_elseif_assign = function(ifstm)
  for i = 4, #ifstm do
    local case = ifstm[i]
    if ntype(case) == "elseif" and ntype(case[2]) == "assign" then
      local split = {
        unpack(ifstm, 1, i - 1)
      }
      insert(split, {
        "else",
        {
          {
            "if",
            case[2],
            case[3],
            unpack(ifstm, i + 1)
          }
        }
      })
      return split
    end
  end
  return ifstm
end
local constructor_name = "new"
local with_continue_listener
with_continue_listener = function(body)
  local continue_name = nil
  return {
    Run(function(self)
      return self:listen("continue", function()
        if not (continue_name) then
          continue_name = NameProxy("continue")
          self:put_name(continue_name)
        end
        return continue_name
      end)
    end),
    build.group(body),
    Run(function(self)
      if not (continue_name) then
        return 
      end
      self:put_name(continue_name, nil)
      return self:splice(function(lines)
        return {
          {
            "assign",
            {
              continue_name
            },
            {
              "false"
            }
          },
          {
            "repeat",
            "true",
            {
              lines,
              {
                "assign",
                {
                  continue_name
                },
                {
                  "true"
                }
              }
            }
          },
          {
            "if",
            {
              "not",
              continue_name
            },
            {
              {
                "break"
              }
            }
          }
        }
      end)
    end)
  }
end
local Transformer
do
  local _parent_0 = nil
  local _base_0 = {
    transform = function(self, scope, node, ...)
      if self.seen_nodes[node] then
        return node
      end
      self.seen_nodes[node] = true
      while true do
        local transformer = self.transformers[ntype(node)]
        local res
        if transformer then
          res = transformer(scope, node, ...) or node
        else
          res = node
        end
        if res == node then
          return node
        end
        node = res
      end
      return node
    end,
    bind = function(self, scope)
      return function(...)
        return self:transform(scope, ...)
      end
    end,
    __call = function(self, ...)
      return self:transform(...)
    end,
    can_transform = function(self, node)
      return self.transformers[ntype(node)] ~= nil
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self, transformers)
      self.transformers = transformers
      self.seen_nodes = setmetatable({ }, {
        __mode = "k"
      })
    end,
    __base = _base_0,
    __name = "Transformer",
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
  Transformer = _class_0
end
local construct_comprehension
construct_comprehension = function(inner, clauses)
  local current_stms = inner
  for _, clause in reversed(clauses) do
    local t = clause[1]
    if t == "for" then
      local names, iter
      _, names, iter = unpack(clause)
      current_stms = {
        "foreach",
        names,
        {
          iter
        },
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
  return current_stms[1]
end
Statement = Transformer({
  root_stms = function(self, body)
    return apply_to_last(body, implicitly_return(self))
  end,
  assign = function(self, node)
    local names, values = unpack(node, 2)
    local transformed
    if #values == 1 then
      local value = values[1]
      local t = ntype(value)
      if t == "decorated" then
        value = self.transform.statement(value)
        t = ntype(value)
      end
      if types.cascading[t] then
        local ret
        ret = function(stm)
          if types.is_value(stm) then
            return {
              "assign",
              names,
              {
                stm
              }
            }
          else
            return stm
          end
        end
        transformed = build.group({
          {
            "declare",
            names
          },
          self.transform.statement(value, ret, node)
        })
      end
    end
    return transformed or node
  end,
  continue = function(self, node)
    local continue_name = self:send("continue")
    if not (continue_name) then
      error("continue must be inside of a loop")
    end
    return build.group({
      build.assign_one(continue_name, "true"),
      {
        "break"
      }
    })
  end,
  export = function(self, node)
    if #node > 2 then
      if node[2] == "class" then
        local cls = smart_node(node[3])
        return build.group({
          {
            "export",
            {
              cls.name
            }
          },
          cls
        })
      else
        return build.group({
          node,
          build.assign({
            names = node[2],
            values = node[3]
          })
        })
      end
    else
      return nil
    end
  end,
  update = function(self, node)
    local _, name, op, exp = unpack(node)
    local op_final = op:match("^(.+)=$")
    if not op_final then
      error("Unknown op: " .. op)
    end
    if not (value_is_singular(exp)) then
      exp = {
        "parens",
        exp
      }
    end
    return build.assign_one(name, {
      "exp",
      name,
      op_final,
      exp
    })
  end,
  import = function(self, node)
    local _, names, source = unpack(node)
    local stubs = (function()
      local _accum_0 = { }
      local _len_0 = 0
      local _list_0 = names
      for _index_0 = 1, #_list_0 do
        local name = _list_0[_index_0]
        local _value_0
        if type(name) == "table" then
          _value_0 = name
        else
          _value_0 = {
            "dot",
            name
          }
        end
        if _value_0 ~= nil then
          _len_0 = _len_0 + 1
          _accum_0[_len_0] = _value_0
        end
      end
      return _accum_0
    end)()
    local real_names = (function()
      local _accum_0 = { }
      local _len_0 = 0
      local _list_0 = names
      for _index_0 = 1, #_list_0 do
        local name = _list_0[_index_0]
        local _value_0 = type(name) == "table" and name[2] or name
        if _value_0 ~= nil then
          _len_0 = _len_0 + 1
          _accum_0[_len_0] = _value_0
        end
      end
      return _accum_0
    end)()
    if type(source) == "string" then
      return build.assign({
        names = real_names,
        values = (function()
          local _accum_0 = { }
          local _len_0 = 0
          local _list_0 = stubs
          for _index_0 = 1, #_list_0 do
            local stub = _list_0[_index_0]
            _len_0 = _len_0 + 1
            _accum_0[_len_0] = build.chain({
              base = source,
              stub
            })
          end
          return _accum_0
        end)()
      })
    else
      local source_name = NameProxy("table")
      return build.group({
        {
          "declare",
          real_names
        },
        build["do"]({
          build.assign_one(source_name, source),
          build.assign({
            names = real_names,
            values = (function()
              local _accum_0 = { }
              local _len_0 = 0
              local _list_0 = stubs
              for _index_0 = 1, #_list_0 do
                local stub = _list_0[_index_0]
                _len_0 = _len_0 + 1
                _accum_0[_len_0] = build.chain({
                  base = source_name,
                  stub
                })
              end
              return _accum_0
            end)()
          })
        })
      })
    end
  end,
  comprehension = function(self, node, action)
    local _, exp, clauses = unpack(node)
    action = action or function(exp)
      return {
        exp
      }
    end
    return construct_comprehension(action(exp), clauses)
  end,
  ["do"] = function(self, node, ret)
    if ret then
      node[2] = apply_to_last(node[2], ret)
    end
    return node
  end,
  decorated = function(self, node)
    local stm, dec = unpack(node, 2)
    local wrapped
    local _exp_0 = dec[1]
    if "if" == _exp_0 then
      local cond, fail = unpack(dec, 2)
      if fail then
        fail = {
          "else",
          {
            fail
          }
        }
      end
      wrapped = {
        "if",
        cond,
        {
          stm
        },
        fail
      }
    elseif "unless" == _exp_0 then
      wrapped = {
        "unless",
        dec[2],
        {
          stm
        }
      }
    elseif "comprehension" == _exp_0 then
      wrapped = {
        "comprehension",
        stm,
        dec[2]
      }
    else
      wrapped = error("Unknown decorator " .. dec[1])
    end
    if ntype(stm) == "assign" then
      wrapped = build.group({
        build.declare({
          names = (function()
            local _accum_0 = { }
            local _len_0 = 0
            local _list_0 = stm[2]
            for _index_0 = 1, #_list_0 do
              local name = _list_0[_index_0]
              if type(name) == "string" then
                _len_0 = _len_0 + 1
                _accum_0[_len_0] = name
              end
            end
            return _accum_0
          end)()
        }),
        wrapped
      })
    end
    return wrapped
  end,
  unless = function(self, node)
    return {
      "if",
      {
        "not",
        {
          "parens",
          node[2]
        }
      },
      unpack(node, 3)
    }
  end,
  ["if"] = function(self, node, ret)
    if ntype(node[2]) == "assign" then
      local _, assign, body = unpack(node)
      local name = assign[2][1]
      return build["do"]({
        assign,
        {
          "if",
          name,
          unpack(node, 3)
        }
      })
    end
    node = expand_elseif_assign(node)
    if ret then
      smart_node(node)
      node['then'] = apply_to_last(node['then'], ret)
      for i = 4, #node do
        local case = node[i]
        local body_idx = #node[i]
        case[body_idx] = apply_to_last(case[body_idx], ret)
      end
    end
    return node
  end,
  with = function(self, node, ret)
    local _, exp, block = unpack(node)
    local scope_name = NameProxy("with")
    local named_assign
    if ntype(exp) == "assign" then
      local names, values = unpack(exp, 2)
      local assign_name = names[1]
      exp = values[1]
      values[1] = scope_name
      named_assign = {
        "assign",
        names,
        values
      }
    end
    return build["do"]({
      Run(function(self)
        return self:set("scope_var", scope_name)
      end),
      build.assign_one(scope_name, exp),
      build.group({
        named_assign
      }),
      build.group(block),
      (function()
        if ret then
          return ret(scope_name)
        end
      end)()
    })
  end,
  foreach = function(self, node)
    smart_node(node)
    local source = unpack(node.iter)
    if ntype(source) == "unpack" then
      local list = source[2]
      local index_name = NameProxy("index")
      local list_name = NameProxy("list")
      local slice_var = nil
      local bounds
      if is_slice(list) then
        local slice = list[#list]
        table.remove(list)
        table.remove(slice, 1)
        if slice[2] and slice[2] ~= "" then
          local max_tmp_name = NameProxy("max")
          slice_var = build.assign_one(max_tmp_name, slice[2])
          slice[2] = {
            "exp",
            max_tmp_name,
            "<",
            0,
            "and",
            {
              "length",
              list_name
            },
            "+",
            max_tmp_name,
            "or",
            max_tmp_name
          }
        else
          slice[2] = {
            "length",
            list_name
          }
        end
        bounds = slice
      else
        bounds = {
          1,
          {
            "length",
            list_name
          }
        }
      end
      return build.group({
        build.assign_one(list_name, list),
        slice_var,
        build["for"]({
          name = index_name,
          bounds = bounds,
          body = {
            {
              "assign",
              node.names,
              {
                list_name:index(index_name)
              }
            },
            build.group(node.body)
          }
        })
      })
    end
    node.body = with_continue_listener(node.body)
  end,
  ["while"] = function(self, node)
    smart_node(node)
    node.body = with_continue_listener(node.body)
  end,
  ["for"] = function(self, node)
    smart_node(node)
    node.body = with_continue_listener(node.body)
  end,
  switch = function(self, node, ret)
    local _, exp, conds = unpack(node)
    local exp_name = NameProxy("exp")
    local convert_cond
    convert_cond = function(cond)
      local t, case_exp, body = unpack(cond)
      local out = { }
      insert(out, t == "case" and "elseif" or "else")
      if t ~= "else" then
        if t ~= "else" then
          insert(out, {
            "exp",
            case_exp,
            "==",
            exp_name
          })
        end
      else
        body = case_exp
      end
      if ret then
        body = apply_to_last(body, ret)
      end
      insert(out, body)
      return out
    end
    local first = true
    local if_stm = {
      "if"
    }
    local _list_0 = conds
    for _index_0 = 1, #_list_0 do
      local cond = _list_0[_index_0]
      local if_cond = convert_cond(cond)
      if first then
        first = false
        insert(if_stm, if_cond[2])
        insert(if_stm, if_cond[3])
      else
        insert(if_stm, if_cond)
      end
    end
    return build.group({
      build.assign_one(exp_name, exp),
      if_stm
    })
  end,
  class = function(self, node, ret, parent_assign)
    local _, name, parent_val, body = unpack(node)
    local statements = { }
    local properties = { }
    local _list_0 = body
    for _index_0 = 1, #_list_0 do
      local item = _list_0[_index_0]
      local _exp_0 = item[1]
      if "stm" == _exp_0 then
        insert(statements, item[2])
      elseif "props" == _exp_0 then
        local _list_1 = item
        for _index_1 = 2, #_list_1 do
          local tuple = _list_1[_index_1]
          if ntype(tuple[1]) == "self" then
            insert(statements, build.assign_one(unpack(tuple)))
          else
            insert(properties, tuple)
          end
        end
      end
    end
    local constructor = nil
    properties = (function()
      local _accum_0 = { }
      local _len_0 = 0
      local _list_1 = properties
      for _index_0 = 1, #_list_1 do
        local tuple = _list_1[_index_0]
        local key = tuple[1]
        local _value_0
        if key[1] == "key_literal" and key[2] == constructor_name then
          constructor = tuple[2]
          _value_0 = nil
        else
          _value_0 = tuple
        end
        if _value_0 ~= nil then
          _len_0 = _len_0 + 1
          _accum_0[_len_0] = _value_0
        end
      end
      return _accum_0
    end)()
    local parent_cls_name = NameProxy("parent")
    local base_name = NameProxy("base")
    local self_name = NameProxy("self")
    local cls_name = NameProxy("class")
    if not constructor then
      constructor = build.fndef({
        args = {
          {
            "..."
          }
        },
        arrow = "fat",
        body = {
          build["if"]({
            cond = parent_cls_name,
            ["then"] = {
              build.chain({
                base = "super",
                {
                  "call",
                  {
                    "..."
                  }
                }
              })
            }
          })
        }
      })
    else
      smart_node(constructor)
      constructor.arrow = "fat"
    end
    local real_name = name or parent_assign and parent_assign[2][1]
    local _exp_0 = ntype(real_name)
    if "chain" == _exp_0 then
      local last = real_name[#real_name]
      local _exp_1 = ntype(last)
      if "dot" == _exp_1 then
        real_name = {
          "string",
          '"',
          last[2]
        }
      elseif "index" == _exp_1 then
        real_name = last[2]
      else
        real_name = "nil"
      end
    elseif "nil" == _exp_0 then
      real_name = "nil"
    else
      real_name = {
        "string",
        '"',
        real_name
      }
    end
    local cls = build.table({
      {
        "__init",
        constructor
      },
      {
        "__base",
        base_name
      },
      {
        "__name",
        real_name
      },
      {
        "__parent",
        parent_cls_name
      }
    })
    local class_lookup = build["if"]({
      cond = {
        "exp",
        "val",
        "==",
        "nil",
        "and",
        parent_cls_name
      },
      ["then"] = {
        parent_cls_name:index("name")
      }
    })
    insert(class_lookup, {
      "else",
      {
        "val"
      }
    })
    local cls_mt = build.table({
      {
        "__index",
        build.fndef({
          args = {
            {
              "cls"
            },
            {
              "name"
            }
          },
          body = {
            build.assign_one(LocalName("val"), build.chain({
              base = "rawget",
              {
                "call",
                {
                  base_name,
                  "name"
                }
              }
            })),
            class_lookup
          }
        })
      },
      {
        "__call",
        build.fndef({
          args = {
            {
              "cls"
            },
            {
              "..."
            }
          },
          body = {
            build.assign_one(self_name, build.chain({
              base = "setmetatable",
              {
                "call",
                {
                  "{}",
                  base_name
                }
              }
            })),
            build.chain({
              base = "cls.__init",
              {
                "call",
                {
                  self_name,
                  "..."
                }
              }
            }),
            self_name
          }
        })
      }
    })
    cls = build.chain({
      base = "setmetatable",
      {
        "call",
        {
          cls,
          cls_mt
        }
      }
    })
    local value = nil
    do
      local _with_0 = build
      local out_body = {
        Run(function(self)
          if name then
            self:put_name(name)
          end
          return self:set("super", function(block, chain)
            if chain then
              local slice = (function()
                local _accum_0 = { }
                local _len_0 = 0
                local _list_1 = chain
                for _index_0 = 3, #_list_1 do
                  local item = _list_1[_index_0]
                  _len_0 = _len_0 + 1
                  _accum_0[_len_0] = item
                end
                return _accum_0
              end)()
              local new_chain = {
                "chain",
                parent_cls_name
              }
              local head = slice[1]
              if head == nil then
                return parent_cls_name
              end
              local _exp_1 = head[1]
              if "call" == _exp_1 then
                local calling_name = block:get("current_block")
                slice[1] = {
                  "call",
                  {
                    "self",
                    unpack(head[2])
                  }
                }
                if ntype(calling_name) == "key_literal" then
                  insert(new_chain, {
                    "dot",
                    calling_name[2]
                  })
                else
                  insert(new_chain, {
                    "index",
                    calling_name
                  })
                end
              elseif "colon" == _exp_1 then
                local call = head[3]
                insert(new_chain, {
                  "dot",
                  head[2]
                })
                slice[1] = {
                  "call",
                  {
                    "self",
                    unpack(call[2])
                  }
                }
              end
              local _list_1 = slice
              for _index_0 = 1, #_list_1 do
                local item = _list_1[_index_0]
                insert(new_chain, item)
              end
              return new_chain
            else
              return parent_cls_name
            end
          end)
        end),
        _with_0.assign_one(parent_cls_name, parent_val == "" and "nil" or parent_val),
        _with_0.assign_one(base_name, {
          "table",
          properties
        }),
        _with_0.assign_one(base_name:chain("__index"), base_name),
        _with_0["if"]({
          cond = parent_cls_name,
          ["then"] = {
            _with_0.chain({
              base = "setmetatable",
              {
                "call",
                {
                  base_name,
                  _with_0.chain({
                    base = parent_cls_name,
                    {
                      "dot",
                      "__base"
                    }
                  })
                }
              }
            })
          }
        }),
        _with_0.assign_one(cls_name, cls),
        _with_0.assign_one(base_name:chain("__class"), cls_name),
        _with_0.group((function()
          if #statements > 0 then
            return {
              _with_0.assign_one(LocalName("self"), cls_name),
              _with_0.group(statements)
            }
          end
        end)()),
        _with_0["if"]({
          cond = {
            "exp",
            parent_cls_name,
            "and",
            parent_cls_name:chain("__inherited")
          },
          ["then"] = {
            parent_cls_name:chain("__inherited", {
              "call",
              {
                parent_cls_name,
                cls_name
              }
            })
          }
        }),
        _with_0.group((function()
          if name then
            return {
              _with_0.assign_one(name, cls_name)
            }
          end
        end)()),
        (function()
          if ret then
            return ret(cls_name)
          end
        end)()
      }
      hoist_declarations(out_body)
      value = _with_0.group({
        _with_0.group((function()
          if ntype(name) == "value" then
            return {
              _with_0.declare({
                names = {
                  name
                }
              })
            }
          end
        end)()),
        _with_0["do"](out_body)
      })
    end
    return value
  end
})
local Accumulator
do
  local _parent_0 = nil
  local _base_0 = {
    body_idx = {
      ["for"] = 4,
      ["while"] = 3,
      foreach = 4
    },
    convert = function(self, node)
      local index = self.body_idx[ntype(node)]
      node[index] = self:mutate_body(node[index])
      return self:wrap(node)
    end,
    wrap = function(self, node)
      return build.block_exp({
        build.assign_one(self.accum_name, build.table()),
        build.assign_one(self.len_name, 0),
        node,
        self.accum_name
      })
    end,
    mutate_body = function(self, body, skip_nil)
      if skip_nil == nil then
        skip_nil = true
      end
      local val
      if not skip_nil and is_singular(body) then
        do
          local _with_0 = body[1]
          body = { }
          val = _with_0
        end
      else
        body = apply_to_last(body, function(n)
          if types.is_value(n) then
            return build.assign_one(self.value_name, n)
          else
            return build.group({
              {
                "declare",
                {
                  self.value_name
                }
              },
              n
            })
          end
        end)
        val = self.value_name
      end
      local update = {
        {
          "update",
          self.len_name,
          "+=",
          1
        },
        build.assign_one(self.accum_name:index(self.len_name), val)
      }
      if skip_nil then
        table.insert(body, build["if"]({
          cond = {
            "exp",
            self.value_name,
            "!=",
            "nil"
          },
          ["then"] = update
        }))
      else
        table.insert(body, build.group(update))
      end
      return body
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self)
      self.accum_name = NameProxy("accum")
      self.value_name = NameProxy("value")
      self.len_name = NameProxy("len")
    end,
    __base = _base_0,
    __name = "Accumulator",
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
  Accumulator = _class_0
end
local default_accumulator
default_accumulator = function(self, node)
  return Accumulator():convert(node)
end
implicitly_return = function(scope)
  local is_top = true
  local fn
  fn = function(stm)
    local t = ntype(stm)
    if t == "decorated" then
      stm = scope.transform.statement(stm)
      t = ntype(stm)
    end
    if types.cascading[t] then
      is_top = false
      return scope.transform.statement(stm, fn)
    elseif types.manual_return[t] or not types.is_value(stm) then
      if is_top and t == "return" and stm[2] == "" then
        return nil
      else
        return stm
      end
    else
      if t == "comprehension" and not types.comprehension_has_value(stm) then
        return stm
      else
        return {
          "return",
          stm
        }
      end
    end
  end
  return fn
end
Value = Transformer({
  ["for"] = default_accumulator,
  ["while"] = default_accumulator,
  foreach = default_accumulator,
  ["do"] = function(self, node)
    return build.block_exp(node[2])
  end,
  decorated = function(self, node)
    return self.transform.statement(node)
  end,
  class = function(self, node)
    return build.block_exp({
      node
    })
  end,
  string = function(self, node)
    local delim = node[2]
    local convert_part
    convert_part = function(part)
      if type(part) == "string" or part == nil then
        return {
          "string",
          delim,
          part or ""
        }
      else
        return build.chain({
          base = "tostring",
          {
            "call",
            {
              part[2]
            }
          }
        })
      end
    end
    if #node <= 3 then
      return (function()
        if type(node[3]) == "string" then
          return node
        else
          return convert_part(node[3])
        end
      end)()
    end
    local e = {
      "exp",
      convert_part(node[3])
    }
    for i = 4, #node do
      insert(e, "..")
      insert(e, convert_part(node[i]))
    end
    return e
  end,
  comprehension = function(self, node)
    local a = Accumulator()
    node = self.transform.statement(node, function(exp)
      return a:mutate_body({
        exp
      }, false)
    end)
    return a:wrap(node)
  end,
  tblcomprehension = function(self, node)
    local _, explist, clauses = unpack(node)
    local key_exp, value_exp = unpack(explist)
    local accum = NameProxy("tbl")
    local inner
    if value_exp then
      local dest = build.chain({
        base = accum,
        {
          "index",
          key_exp
        }
      })
      inner = {
        build.assign_one(dest, value_exp)
      }
    else
      local key_name, val_name = NameProxy("key"), NameProxy("val")
      local dest = build.chain({
        base = accum,
        {
          "index",
          key_name
        }
      })
      inner = {
        build.assign({
          names = {
            key_name,
            val_name
          },
          values = {
            key_exp
          }
        }),
        build.assign_one(dest, val_name)
      }
    end
    return build.block_exp({
      build.assign_one(accum, build.table()),
      construct_comprehension(inner, clauses),
      accum
    })
  end,
  fndef = function(self, node)
    smart_node(node)
    node.body = apply_to_last(node.body, implicitly_return(self))
    node.body = {
      Run(function(self)
        return self:listen("varargs", function() end)
      end),
      unpack(node.body)
    }
    return node
  end,
  ["if"] = function(self, node)
    return build.block_exp({
      node
    })
  end,
  unless = function(self, node)
    return build.block_exp({
      node
    })
  end,
  with = function(self, node)
    return build.block_exp({
      node
    })
  end,
  switch = function(self, node)
    return build.block_exp({
      node
    })
  end,
  chain = function(self, node)
    local stub = node[#node]
    for i = 3, #node do
      local part = node[i]
      if ntype(part) == "dot" and data.lua_keywords[part[2]] then
        node[i] = {
          "index",
          {
            "string",
            '"',
            part[2]
          }
        }
      end
    end
    if ntype(node[2]) == "string" then
      node[2] = {
        "parens",
        node[2]
      }
    elseif type(stub) == "table" and stub[1] == "colon_stub" then
      table.remove(node, #node)
      local base_name = NameProxy("base")
      local fn_name = NameProxy("fn")
      local is_super = node[2] == "super"
      return self.transform.value(build.block_exp({
        build.assign({
          names = {
            base_name
          },
          values = {
            node
          }
        }),
        build.assign({
          names = {
            fn_name
          },
          values = {
            build.chain({
              base = base_name,
              {
                "dot",
                stub[2]
              }
            })
          }
        }),
        build.fndef({
          args = {
            {
              "..."
            }
          },
          body = {
            build.chain({
              base = fn_name,
              {
                "call",
                {
                  is_super and "self" or base_name,
                  "..."
                }
              }
            })
          }
        })
      }))
    end
  end,
  block_exp = function(self, node)
    local _, body = unpack(node)
    local fn = nil
    local arg_list = { }
    fn = smart_node(build.fndef({
      body = {
        Run(function(self)
          return self:listen("varargs", function()
            insert(arg_list, "...")
            insert(fn.args, {
              "..."
            })
            return self:unlisten("varargs")
          end)
        end),
        unpack(body)
      }
    }))
    return build.chain({
      base = {
        "parens",
        fn
      },
      {
        "call",
        arg_list
      }
    })
  end
})
