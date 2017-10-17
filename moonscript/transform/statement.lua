local Transformer
Transformer = require("moonscript.transform.transformer").Transformer
local NameProxy, LocalName, is_name_proxy
do
  local _obj_0 = require("moonscript.transform.names")
  NameProxy, LocalName, is_name_proxy = _obj_0.NameProxy, _obj_0.LocalName, _obj_0.is_name_proxy
end
local Run, transform_last_stm, implicitly_return, last_stm
do
  local _obj_0 = require("moonscript.transform.statements")
  Run, transform_last_stm, implicitly_return, last_stm = _obj_0.Run, _obj_0.transform_last_stm, _obj_0.implicitly_return, _obj_0.last_stm
end
local types = require("moonscript.types")
local build, ntype, is_value, smart_node, value_is_singular, is_slice, NOOP
build, ntype, is_value, smart_node, value_is_singular, is_slice, NOOP = types.build, types.ntype, types.is_value, types.smart_node, types.value_is_singular, types.is_slice, types.NOOP
local insert
insert = table.insert
local destructure = require("moonscript.transform.destructure")
local construct_comprehension
construct_comprehension = require("moonscript.transform.comprehension").construct_comprehension
local unpack
unpack = require("moonscript.util").unpack
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
      local last = last_stm(body)
      local enclose_lines = types.terminating[last and ntype(last)]
      self:put_name(continue_name, nil)
      return self:splice(function(lines)
        if enclose_lines then
          lines = {
            "do",
            {
              lines
            }
          }
        end
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
local extract_declarations
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
          if ntype(name) == "ref" then
            insert(out, name)
          elseif type(name) == "string" then
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
return Transformer({
  transform = function(self, tuple)
    local _, node, fn
    _, node, fn = tuple[1], tuple[2], tuple[3]
    return fn(node)
  end,
  root_stms = function(self, body)
    return transform_last_stm(body, implicitly_return(self))
  end,
  ["return"] = function(self, node)
    local ret_val = node[2]
    local ret_val_type = ntype(ret_val)
    if ret_val_type == "explist" and #ret_val == 2 then
      ret_val = ret_val[2]
      ret_val_type = ntype(ret_val)
    end
    if types.cascading[ret_val_type] then
      return implicitly_return(self)(ret_val)
    end
    if ret_val_type == "chain" or ret_val_type == "comprehension" or ret_val_type == "tblcomprehension" then
      local Value = require("moonscript.transform.value")
      ret_val = Value:transform_once(self, ret_val)
      if ntype(ret_val) == "block_exp" then
        return build.group(transform_last_stm(ret_val[2], function(stm)
          return {
            "return",
            stm
          }
        end))
      end
    end
    node[2] = ret_val
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
            local str_name
            if ntype(name) == "ref" then
              str_name = name[2]
            else
              str_name = name
            end
            if not (str_name:match("^%u")) then
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
      local first_type = ntype(first_value)
      if first_type == "chain" then
        local Value = require("moonscript.transform.value")
        first_value = Value:transform_once(self, first_value)
        first_type = ntype(first_value)
      end
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
        local Value = require("moonscript.transform.value")
        return build.assign_one(first_name, Value:transform_once(self, first_value))
      else
        values[1] = first_value
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
          if is_value(stm) then
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
    local name, op, exp = unpack(node, 2)
    local op_final = op:match("^(.+)=$")
    if not op_final then
      error("Unknown op: " .. op)
    end
    local lifted
    if ntype(name) == "chain" then
      lifted = { }
      local new_chain
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 3, #name do
          local part = name[_index_0]
          if ntype(part) == "index" then
            local proxy = NameProxy("update")
            table.insert(lifted, {
              proxy,
              part[2]
            })
            _accum_0[_len_0] = {
              "index",
              proxy
            }
          else
            _accum_0[_len_0] = part
          end
          _len_0 = _len_0 + 1
        end
        new_chain = _accum_0
      end
      if next(lifted) then
        name = {
          name[1],
          name[2],
          unpack(new_chain)
        }
      end
    end
    if not (value_is_singular(exp)) then
      exp = {
        "parens",
        exp
      }
    end
    local out = build.assign_one(name, {
      "exp",
      name,
      op_final,
      exp
    })
    if lifted and next(lifted) then
      local names
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #lifted do
          local l = lifted[_index_0]
          _accum_0[_len_0] = l[1]
          _len_0 = _len_0 + 1
        end
        names = _accum_0
      end
      local values
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #lifted do
          local l = lifted[_index_0]
          _accum_0[_len_0] = l[2]
          _len_0 = _len_0 + 1
        end
        values = _accum_0
      end
      out = build.group({
        {
          "assign",
          names,
          values
        },
        out
      })
    end
    return out
  end,
  import = function(self, node)
    local names, source = unpack(node, 2)
    local table_values
    do
      local _accum_0 = { }
      local _len_0 = 1
      for _index_0 = 1, #names do
        local name = names[_index_0]
        local dest_name
        if ntype(name) == "colon" then
          dest_name = name[2]
        else
          dest_name = name
        end
        local _value_0 = {
          {
            "key_literal",
            name
          },
          dest_name
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
    local exp, clauses = unpack(node, 2)
    action = action or function(exp)
      return {
        exp
      }
    end
    return construct_comprehension(action(exp), clauses)
  end,
  ["do"] = function(self, node, ret)
    if ret then
      node[2] = transform_last_stm(node[2], ret)
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
              if ntype(name) == "ref" then
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
    local clause = node[2]
    if ntype(clause) == "assign" then
      if destructure.has_destructure(clause[2]) then
        error("destructure not allowed in unless assignment")
      end
      return build["do"]({
        clause,
        {
          "if",
          {
            "not",
            clause[2][1]
          },
          unpack(node, 3)
        }
      })
    else
      return {
        "if",
        {
          "not",
          {
            "parens",
            clause
          }
        },
        unpack(node, 3)
      }
    end
  end,
  ["if"] = function(self, node, ret)
    if ntype(node[2]) == "assign" then
      local assign, body = unpack(node, 2)
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
      node['then'] = transform_last_stm(node['then'], ret)
      for i = 4, #node do
        local case = node[i]
        local body_idx = #node[i]
        case[body_idx] = transform_last_stm(case[body_idx], ret)
      end
    end
    return node
  end,
  with = function(self, node, ret)
    local exp, block = unpack(node, 2)
    local copy_scope = true
    local scope_name, named_assign
    do
      local last = last_stm(block)
      if last then
        if types.terminating[ntype(last)] then
          ret = false
        end
      end
    end
    if ntype(exp) == "assign" then
      local names, values = unpack(exp, 2)
      local first_name = names[1]
      if ntype(first_name) == "ref" then
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
    local out = build["do"]({
      copy_scope and build.assign_one(scope_name, exp) or NOOP,
      named_assign or NOOP,
      Run(function(self)
        return self:set("scope_var", scope_name)
      end),
      unpack(block)
    })
    if ret then
      table.insert(out[2], ret(scope_name))
    end
    return out
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
      local names
      do
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = node.names
        for _index_0 = 1, #_list_0 do
          local n = _list_0[_index_0]
          _accum_0[_len_0] = is_name_proxy(n) and n or LocalName(n) or n
          _len_0 = _len_0 + 1
        end
        names = _accum_0
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
              names,
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
    local exp, conds = unpack(node, 2)
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
        body = transform_last_stm(body, ret)
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
  class = require("moonscript.transform.class")
})
