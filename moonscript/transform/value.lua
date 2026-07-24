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
