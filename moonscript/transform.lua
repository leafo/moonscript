local types = require("moonscript.types")
local util = require("moonscript.util")
local data = require("moonscript.data")
local reversed, unpack
reversed, unpack = util.reversed, util.unpack
local ntype, mtype, build, smart_node, is_slice, value_is_singular
ntype, mtype, build, smart_node, is_slice, value_is_singular = types.ntype, types.mtype, types.build, types.smart_node, types.is_slice, types.value_is_singular
local insert
do
  local _obj_0 = table
  insert = _obj_0.insert
end
local NameProxy, LocalName
do
  local _obj_0 = require("moonscript.transform.names")
  NameProxy, LocalName = _obj_0.NameProxy, _obj_0.LocalName
end
local destructure = require("moonscript.transform.destructure")
local NOOP = {
  "noop"
}
local Run, apply_to_last, is_singular, extract_declarations, expand_elseif_assign, constructor_name, with_continue_listener, Transformer, construct_comprehension, Statement, Accumulator, default_accumulator, implicitly_return, Value
do
  local _base_0 = {
    call = function(self, state)
      return self.fn(state)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, fn)
      self.fn = fn
      self[1] = "run"
    end,
    __base = _base_0,
    __name = "Run"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Run = _class_0
end
apply_to_last = function(stms, fn)
  local last_exp_id = 0
  for i = #stms, 1, -1 do
    local stm = stms[i]
    if stm and mtype(stm) ~= Run then
      last_exp_id = i
      break
    end
  end
  return (function()
    local _accum_0 = { }
    local _len_0 = 1
    for i, stm in ipairs(stms) do
      if i == last_exp_id then
        _accum_0[_len_0] = {
          "transform",
          stm,
          fn
        }
      else
        _accum_0[_len_0] = stm
      end
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)()
end
is_singular = function(body)
  if #body ~= 1 then
    return false
  end
  if "group" == ntype(body) then
    return is_singular(body[2])
  else
    return body[1]
  end
end
extract_declarations = function(self, body, start, out)
  if body == nil then
    body = self.current_stms
  end
  if start == nil then
    start = self.current_stm_i + 1
  end
  if out == nil then
    out = { }
  end
  for i = start, #body do
    local _continue_0 = false
    repeat
      local stm = body[i]
      if stm == nil then
        _continue_0 = true
        break
      end
      stm = self.transform.statement(stm)
      body[i] = stm
      local _exp_0 = stm[1]
      if "assign" == _exp_0 or "declare" == _exp_0 then
        local _list_0 = stm[2]
        for _index_0 = 1, #_list_0 do
          local name = _list_0[_index_0]
          if type(name) == "string" then
            insert(out, name)
          end
        end
      elseif "group" == _exp_0 then
        extract_declarations(self, stm[2], 1, out)
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  return out
end
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
constructor_name = "new"
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
do
  local _base_0 = {
    transform_once = function(self, scope, node, ...)
      if self.seen_nodes[node] then
        return node
      end
      self.seen_nodes[node] = true
      local transformer = self.transformers[ntype(node)]
      if transformer then
        return transformer(scope, node, ...) or node
      else
        return node
      end
    end,
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
  local _class_0 = setmetatable({
    __init = function(self, transformers)
      self.transformers = transformers
      self.seen_nodes = setmetatable({ }, {
        __mode = "k"
      })
    end,
    __base = _base_0,
    __name = "Transformer"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Transformer = _class_0
end
construct_comprehension = function(inner, clauses)
  local current_stms = inner
  for _, clause in reversed(clauses) do
    local t = clause[1]
    local _exp_0 = t
    if "for" == _exp_0 then
      local name, bounds
      _, name, bounds = clause[1], clause[2], clause[3]
      current_stms = {
        "for",
        name,
        bounds,
        current_stms
      }
    elseif "foreach" == _exp_0 then
      local names, iter
      _, names, iter = clause[1], clause[2], clause[3]
      current_stms = {
        "foreach",
        names,
        {
          iter
        },
        current_stms
      }
    elseif "when" == _exp_0 then
      local cond
      _, cond = clause[1], clause[2]
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
  transform = function(self, tuple)
    local _, node, fn
    _, node, fn = tuple[1], tuple[2], tuple[3]
    return fn(node)
  end,
  root_stms = function(self, body)
    return apply_to_last(body, implicitly_return(self))
  end,
  ["return"] = function(self, node)
    node[2] = Value:transform_once(self, node[2])
    if "block_exp" == ntype(node[2]) then
      local block_exp = node[2]
      local block_body = block_exp[2]
      local idx = #block_body
      node[2] = block_body[idx]
      block_body[idx] = node
      return build.group(block_body)
    end
    return node
  end,
  declare_glob = function(self, node)
    local names = extract_declarations(self)
    if node[2] == "^" then
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #names do
          local _continue_0 = false
          repeat
            local name = names[_index_0]
            if not (name:match("^%u")) then
              _continue_0 = true
              break
            end
            local _value_0 = name
            _accum_0[_len_0] = _value_0
            _len_0 = _len_0 + 1
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
        names = _accum_0
      end
    end
    return {
      "declare",
      names
    }
  end,
  assign = function(self, node)
    local names, values = unpack(node, 2)
    local num_values = #values
    local num_names = #values
    if num_names == 1 and num_values == 1 then
      local first_value = values[1]
      local first_name = names[1]
      local _exp_0 = ntype(first_value)
      if "block_exp" == _exp_0 then
        local block_body = first_value[2]
        local idx = #block_body
        block_body[idx] = build.assign_one(first_name, block_body[idx])
        return build.group({
          {
            "declare",
            {
              first_name
            }
          },
          {
            "do",
            block_body
          }
        })
      elseif "comprehension" == _exp_0 or "tblcomprehension" == _exp_0 or "foreach" == _exp_0 or "for" == _exp_0 or "while" == _exp_0 then
        return build.assign_one(first_name, Value:transform_once(self, first_value))
      end
    end
    local transformed
    if num_values == 1 then
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
    node = transformed or node
    if destructure.has_destructure(names) then
      return destructure.split_assign(self, node)
    end
    return node
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
          {
            "export",
            node[2]
          },
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
    local table_values
    do
      local _accum_0 = { }
      local _len_0 = 1
      for _index_0 = 1, #names do
        local name = names[_index_0]
        local dest_val
        if ntype(name) == "colon_stub" then
          dest_val = name[2]
        else
          dest_val = name
        end
        local _value_0 = {
          {
            "key_literal",
            name
          },
          dest_val
        }
        _accum_0[_len_0] = _value_0
        _len_0 = _len_0 + 1
      end
      table_values = _accum_0
    end
    local dest = {
      "table",
      table_values
    }
    return {
      "assign",
      {
        dest
      },
      {
        source
      },
      [-1] = node[-1]
    }
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
            local _len_0 = 1
            local _list_0 = stm[2]
            for _index_0 = 1, #_list_0 do
              local name = _list_0[_index_0]
              if type(name) == "string" then
                _accum_0[_len_0] = name
                _len_0 = _len_0 + 1
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
      if destructure.has_destructure(assign[2]) then
        local name = NameProxy("des")
        body = {
          destructure.build_assign(self, assign[2][1], name),
          build.group(node[3])
        }
        return build["do"]({
          build.assign_one(name, assign[3][1]),
          {
            "if",
            name,
            body,
            unpack(node, 4)
          }
        })
      else
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
    local exp, block = unpack(node, 2)
    local copy_scope = true
    local scope_name, named_assign
    if ntype(exp) == "assign" then
      local names, values = unpack(exp, 2)
      local first_name = names[1]
      if ntype(first_name) == "value" then
        scope_name = first_name
        named_assign = exp
        exp = values[1]
        copy_scope = false
      else
        scope_name = NameProxy("with")
        exp = values[1]
        values[1] = scope_name
        named_assign = {
          "assign",
          names,
          values
        }
      end
    elseif self:is_local(exp) then
      scope_name = exp
      copy_scope = false
    end
    scope_name = scope_name or NameProxy("with")
    return build["do"]({
      Run(function(self)
        return self:set("scope_var", scope_name)
      end),
      copy_scope and build.assign_one(scope_name, exp) or NOOP,
      named_assign or NOOP,
      build.group(block),
      (function()
        if ret then
          return ret(scope_name)
        end
      end)()
    })
  end,
  foreach = function(self, node, _)
    smart_node(node)
    local source = unpack(node.iter)
    local destructures = { }
    do
      local _accum_0 = { }
      local _len_0 = 1
      for i, name in ipairs(node.names) do
        if ntype(name) == "table" then
          do
            local proxy = NameProxy("des")
            insert(destructures, destructure.build_assign(self, name, proxy))
            _accum_0[_len_0] = proxy
          end
        else
          _accum_0[_len_0] = name
        end
        _len_0 = _len_0 + 1
      end
      node.names = _accum_0
    end
    if next(destructures) then
      insert(destructures, build.group(node.body))
      node.body = destructures
    end
    if ntype(source) == "unpack" then
      local list = source[2]
      local index_name = NameProxy("index")
      local list_name = self:is_local(list) and list or NameProxy("list")
      local slice_var = nil
      local bounds
      if is_slice(list) then
        local slice = list[#list]
        table.remove(list)
        table.remove(slice, 1)
        if self:is_local(list) then
          list_name = list
        end
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
        list_name ~= list and build.assign_one(list_name, list) or NOOP,
        slice_var or NOOP,
        build["for"]({
          name = index_name,
          bounds = bounds,
          body = {
            {
              "assign",
              node.names,
              {
                NameProxy.index(list_name, index_name)
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
      local t, case_exps, body = unpack(cond)
      local out = { }
      insert(out, t == "case" and "elseif" or "else")
      if t ~= "else" then
        local cond_exp = { }
        for i, case in ipairs(case_exps) do
          if i == 1 then
            insert(cond_exp, "exp")
          else
            insert(cond_exp, "or")
          end
          if not (value_is_singular(case)) then
            case = {
              "parens",
              case
            }
          end
          insert(cond_exp, {
            "exp",
            case,
            "==",
            exp_name
          })
        end
        insert(out, cond_exp)
      else
        body = case_exps
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
    for _index_0 = 1, #conds do
      local cond = conds[_index_0]
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
    if parent_val == "" then
      parent_val = nil
    end
    local statements = { }
    local properties = { }
    for _index_0 = 1, #body do
      local item = body[_index_0]
      local _exp_0 = item[1]
      if "stm" == _exp_0 then
        insert(statements, item[2])
      elseif "props" == _exp_0 then
        for _index_1 = 2, #item do
          local tuple = item[_index_1]
          if ntype(tuple[1]) == "self" then
            insert(statements, build.assign_one(unpack(tuple)))
          else
            insert(properties, tuple)
          end
        end
      end
    end
    local constructor
    do
      local _accum_0 = { }
      local _len_0 = 1
      for _index_0 = 1, #properties do
        local _continue_0 = false
        repeat
          local tuple = properties[_index_0]
          local key = tuple[1]
          local _value_0
          if key[1] == "key_literal" and key[2] == constructor_name then
            constructor = tuple[2]
            _continue_0 = true
            break
          else
            _value_0 = tuple
          end
          _accum_0[_len_0] = _value_0
          _len_0 = _len_0 + 1
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      properties = _accum_0
    end
    local parent_cls_name = NameProxy("parent")
    local base_name = NameProxy("base")
    local self_name = NameProxy("self")
    local cls_name = NameProxy("class")
    if not (constructor) then
      if parent_val then
        constructor = build.fndef({
          args = {
            {
              "..."
            }
          },
          arrow = "fat",
          body = {
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
      else
        constructor = build.fndef()
      end
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
      parent_val and {
        "__parent",
        parent_cls_name
      } or nil
    })
    local class_index
    if parent_val then
      local class_lookup = build["if"]({
        cond = {
          "exp",
          "val",
          "==",
          "nil"
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
      class_index = build.fndef({
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
    else
      class_index = base_name
    end
    local cls_mt = build.table({
      {
        "__index",
        class_index
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
      local out_body = {
        Run(function(self)
          if name then
            self:put_name(name)
          end
          return self:set("super", function(block, chain)
            if chain then
              local slice
              do
                local _accum_0 = { }
                local _len_0 = 1
                for _index_0 = 3, #chain do
                  local item = chain[_index_0]
                  _accum_0[_len_0] = item
                  _len_0 = _len_0 + 1
                end
                slice = _accum_0
              end
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
              for _index_0 = 1, #slice do
                local item = slice[_index_0]
                insert(new_chain, item)
              end
              return new_chain
            else
              return parent_cls_name
            end
          end)
        end),
        {
          "declare_glob",
          "*"
        },
        parent_val and build.assign_one(parent_cls_name, parent_val) or NOOP,
        build.assign_one(base_name, {
          "table",
          properties
        }),
        build.assign_one(base_name:chain("__index"), base_name),
        parent_val and build.chain({
          base = "setmetatable",
          {
            "call",
            {
              base_name,
              build.chain({
                base = parent_cls_name,
                {
                  "dot",
                  "__base"
                }
              })
            }
          }
        }) or NOOP,
        build.assign_one(cls_name, cls),
        build.assign_one(base_name:chain("__class"), cls_name),
        build.group((function()
          if #statements > 0 then
            return {
              build.assign_one(LocalName("self"), cls_name),
              build.group(statements)
            }
          end
        end)()),
        parent_val and build["if"]({
          cond = {
            "exp",
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
        }) or NOOP,
        build.group((function()
          if name then
            return {
              build.assign_one(name, cls_name)
            }
          end
        end)()),
        (function()
          if ret then
            return ret(cls_name)
          end
        end)()
      }
      value = build.group({
        build.group((function()
          if ntype(name) == "value" then
            return {
              build.declare({
                names = {
                  name
                }
              })
            }
          end
        end)()),
        build["do"](out_body)
      })
    end
    return value
  end
})
do
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
    wrap = function(self, node, group_type)
      if group_type == nil then
        group_type = "block_exp"
      end
      return build[group_type]({
        build.assign_one(self.accum_name, build.table()),
        build.assign_one(self.len_name, 1),
        node,
        group_type == "block_exp" and self.accum_name or NOOP
      })
    end,
    mutate_body = function(self, body)
      local single_stm = is_singular(body)
      local val
      if single_stm and types.is_value(single_stm) then
        body = { }
        val = single_stm
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
        build.assign_one(NameProxy.index(self.accum_name, self.len_name), val),
        {
          "update",
          self.len_name,
          "+=",
          1
        }
      }
      insert(body, build.group(update))
      return body
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, accum_name)
      self.accum_name = NameProxy("accum")
      self.value_name = NameProxy("value")
      self.len_name = NameProxy("len")
    end,
    __base = _base_0,
    __name = "Accumulator"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Accumulator = _class_0
end
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
        return NOOP
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
      })
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
return {
  Statement = Statement,
  Value = Value,
  Run = Run
}
