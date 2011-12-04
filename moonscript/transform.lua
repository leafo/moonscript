module("moonscript.transform", package.seeall)
local types = require("moonscript.types")
local util = require("moonscript.util")
local data = require("moonscript.data")
local reversed = util.reversed
local ntype, build, smart_node, is_slice = types.ntype, types.build, types.smart_node, types.is_slice
local insert = table.insert
LocalName = (function()
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
  return _class_0
end)()
NameProxy = (function()
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
  return _class_0
end)()
Run = (function()
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
  return _class_0
end)()
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
local constructor_name = "new"
local Transformer
Transformer = (function()
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
    end,
    __call = function(self, node, ...)
      return self:transform(self.scope, node, ...)
    end,
    instance = function(self, scope)
      return Transformer(self.transformers, scope)
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
    __init = function(self, transformers, scope)
      self.transformers, self.scope = transformers, scope
      self.seen_nodes = { }
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
  return _class_0
end)()
local construct_comprehension
construct_comprehension = function(inner, clauses)
  local current_stms = inner
  for _, clause in reversed(clauses) do
    local t = clause[1]
    if t == "for" then
      local _, names, iter = unpack(clause)
      current_stms = {
        "foreach",
        names,
        iter,
        current_stms
      }
    elseif t == "when" then
      local _, cond = unpack(clause)
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
  assign = function(self, node)
    local _, names, values = unpack(node)
    if #values == 1 and types.cascading[ntype(values[1])] then
      values[1] = self.transform.statement(values[1], function(stm)
        local t = ntype(stm)
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
      end)
      return build.group({
        {
          "declare",
          names
        },
        values[1]
      })
    else
      return node
    end
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
  ["if"] = function(self, node, ret)
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
    return build["do"]({
      build.assign_one(scope_name, exp),
      Run(function(self)
        return self:set("scope_var", scope_name)
      end),
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
    if ntype(node.iter) == "unpack" then
      local list = node.iter[2]
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
  class = function(self, node)
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
        for _index_0 = 2, #_list_1 do
          local tuple = _list_1[_index_0]
          insert(properties, tuple)
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
        local _value_0
        if tuple[1] == constructor_name then
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
        {
          "string",
          '"',
          name
        }
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
      value = _with_0.block_exp({
        Run(function(self)
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
              local _exp_0 = head[1]
              if "call" == _exp_0 then
                local calling_name = block:get("current_block")
                slice[1] = {
                  "call",
                  {
                    "self",
                    unpack(head[2])
                  }
                }
                local act
                if ntype(calling_name) ~= "value" then
                  act = "index"
                else
                  act = "dot"
                end
                insert(new_chain, {
                  act,
                  calling_name
                })
              elseif "colon" == _exp_0 then
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
        build["if"]({
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
          else
            return { }
          end
        end)()),
        cls_name
      })
      value = _with_0.group({
        _with_0.declare({
          names = {
            name
          }
        }),
        _with_0.assign({
          names = {
            name
          },
          values = {
            value
          }
        })
      })
    end
    return value
  end
})
local Accumulator
Accumulator = (function()
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
          return build.assign_one(self.value_name, n)
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
  return _class_0
end)()
local default_accumulator
default_accumulator = function(self, node)
  return Accumulator():convert(node)
end
local implicitly_return
implicitly_return = function(scope)
  local fn
  fn = function(stm)
    local t = ntype(stm)
    if types.manual_return[t] or not types.is_value(stm) then
      return stm
    elseif types.cascading[t] then
      return scope.transform.statement(stm, fn)
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
    local _, key_exp, value_exp, clauses = unpack(node)
    local accum = NameProxy("tbl")
    local dest = build.chain({
      base = accum,
      {
        "index",
        key_exp
      }
    })
    local inner = build.assign_one(dest, value_exp)
    return build.block_exp({
      build.assign_one(accum, build.table()),
      construct_comprehension({
        inner
      }, clauses),
      accum
    })
  end,
  fndef = function(self, node)
    smart_node(node)
    node.body = apply_to_last(node.body, implicitly_return(self))
    return node
  end,
  ["if"] = function(self, node)
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
    if type(stub) == "table" and stub[1] == "colon_stub" then
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
    insert(body, Run(function(self)
      if self.has_varargs then
        insert(arg_list, "...")
        return insert(fn.args, {
          "..."
        })
      end
    end))
    fn = smart_node(build.fndef({
      body = body
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
