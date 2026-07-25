local Transformer
Transformer = require("moonscript.transform.transformer").Transformer
local build, ntype, smart_node
do
  local _obj_0 = require("moonscript.types")
  build, ntype, smart_node = _obj_0.build, _obj_0.ntype, _obj_0.smart_node
end
local NameProxy
NameProxy = require("moonscript.transform.names").NameProxy
local Accumulator, default_accumulator
do
  local _obj_0 = require("moonscript.transform.accumulator")
  Accumulator, default_accumulator = _obj_0.Accumulator, _obj_0.default_accumulator
end
local lua_keywords
lua_keywords = require("moonscript.data").lua_keywords
local user_error
user_error = require("moonscript.errors").user_error
local transform_last_stm, implicitly_return, chain_is_stub, has_varargs
do
  local _obj_0 = require("moonscript.transform.statements")
  transform_last_stm, implicitly_return, chain_is_stub, has_varargs = _obj_0.transform_last_stm, _obj_0.implicitly_return, _obj_0.chain_is_stub, _obj_0.has_varargs
end
local construct_comprehension
construct_comprehension = require("moonscript.transform.comprehension").construct_comprehension
local destructure = require("moonscript.transform.destructure")
local insert
insert = table.insert
local unpack
unpack = require("moonscript.util").unpack
return Transformer({
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
      if type(node[3]) == "string" then
        return node
      else
        return convert_part(node[3])
      end
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
    local explist, clauses = unpack(node, 2)
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
    node.body = transform_last_stm(node.body, implicitly_return(self))
    local first_destructure
    for i, arg in ipairs(node.args) do
      if ntype(arg[1]) == "table" then
        first_destructure = i
        break
      end
    end
    if first_destructure then
      local bound_names = { }
      if node.arrow == "fat" then
        bound_names.self = true
      end
      local _list_0 = node.args
      for _index_0 = 1, #_list_0 do
        local arg = _list_0[_index_0]
        local _exp_0 = ntype(arg[1])
        if "self" == _exp_0 or "self_class" == _exp_0 then
          bound_names[arg[1][2]] = true
        elseif "table" == _exp_0 then
          local _ = nil
        else
          if type(arg[1]) == "string" then
            bound_names[arg[1]] = true
          end
        end
      end
      local seen_targets = { }
      local _list_1 = node.args
      for _index_0 = 1, #_list_1 do
        local _continue_0 = false
        repeat
          local arg = _list_1[_index_0]
          if not (ntype(arg[1]) == "table") then
            _continue_0 = true
            break
          end
          local targets
          do
            local _accum_0 = { }
            local _len_0 = 1
            local _list_2 = destructure.extract_assign_names(arg[1])
            for _index_1 = 1, #_list_2 do
              local _des_0 = _list_2[_index_1]
              local t
              t = _des_0[1]
              if ntype(t) == "ref" then
                _accum_0[_len_0] = t
                _len_0 = _len_0 + 1
              end
            end
            targets = _accum_0
          end
          for _index_1 = 1, #targets do
            local target = targets[_index_1]
            local name = target[2]
            if bound_names[name] or seen_targets[name] then
              user_error("Can't destructure into '" .. tostring(name) .. "': name is bound by another parameter", target[-1])
            end
          end
          for _index_1 = 1, #targets do
            local target = targets[_index_1]
            seen_targets[target[2]] = true
          end
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      local default_check
      default_check = function(name, value)
        return {
          "if",
          {
            "exp",
            name,
            "==",
            "nil"
          },
          {
            {
              "assign",
              {
                name
              },
              {
                value
              }
            }
          }
        }
      end
      local prelude = { }
      for i = first_destructure, #node.args do
        local arg = node.args[i]
        local name, default_value = arg[1], arg[2]
        local _exp_0 = ntype(name)
        if "table" == _exp_0 then
          local proxy = NameProxy("arg")
          if default_value then
            insert(prelude, default_check(proxy, default_value))
          end
          insert(prelude, destructure.build_assign(self, name, proxy, {
            shadow = true
          }))
          node.args[i] = {
            proxy
          }
        elseif "self" == _exp_0 or "self_class" == _exp_0 then
          local raw_name = name[2]
          if default_value then
            insert(prelude, default_check({
              "ref",
              raw_name
            }, default_value))
          end
          insert(prelude, build.assign_one(name, {
            "ref",
            raw_name
          }))
          node.args[i] = {
            raw_name
          }
        else
          if default_value then
            insert(prelude, default_check({
              "ref",
              name
            }, default_value))
            node.args[i] = {
              name
            }
          end
        end
      end
      insert(prelude, build.group(node.body))
      node.body = prelude
    end
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
    for i = 2, #node do
      local part = node[i]
      if ntype(part) == "dot" and lua_keywords[part[2]] then
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
    end
    if chain_is_stub(node) then
      local base_name = NameProxy("base")
      local fn_name = NameProxy("fn")
      local colon = table.remove(node)
      if not (node[2]) then
        local scope_var = self:get("scope_var")
        if not (scope_var) then
          user_error("Short-colon syntax must be called within a with block", node[-1])
        end
        node[2] = scope_var
      end
      local is_super = ntype(node[2]) == "ref" and node[2][2] == "super"
      return build.block_exp({
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
                colon[2]
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
      })
    end
  end,
  block_exp = function(self, node)
    local body = unpack(node, 2)
    local arg_list = { }
    local fn = smart_node(build.fndef({
      body = body
    }))
    if has_varargs(body) then
      insert(arg_list, "...")
      insert(fn.args, {
        "..."
      })
    end
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
