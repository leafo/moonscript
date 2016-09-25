local NameProxy, LocalName
do
  local _obj_0 = require("moonscript.transform.names")
  NameProxy, LocalName = _obj_0.NameProxy, _obj_0.LocalName
end
local Run
Run = require("moonscript.transform.statements").Run
local CONSTRUCTOR_NAME = "new"
local insert
insert = table.insert
local build, ntype, NOOP
do
  local _obj_0 = require("moonscript.types")
  build, ntype, NOOP = _obj_0.build, _obj_0.ntype, _obj_0.NOOP
end
local unpack
unpack = require("moonscript.util").unpack
local transform_super
transform_super = function(cls_name, on_base, block, chain)
  if on_base == nil then
    on_base = true
  end
  local relative_parent = {
    "chain",
    cls_name,
    {
      "dot",
      "__parent"
    }
  }
  if not (chain) then
    return relative_parent
  end
  local chain_tail = {
    unpack(chain, 3)
  }
  local head = chain_tail[1]
  if head == nil then
    return relative_parent
  end
  local new_chain = relative_parent
  local _exp_0 = head[1]
  if "call" == _exp_0 then
    if on_base then
      insert(new_chain, {
        "dot",
        "__base"
      })
    end
    local calling_name = block:get("current_method")
    assert(calling_name, "missing calling name")
    chain_tail[1] = {
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
  elseif "colon" == _exp_0 then
    local call = chain_tail[2]
    if call and call[1] == "call" then
      chain_tail[1] = {
        "dot",
        head[2]
      }
      chain_tail[2] = {
        "call",
        {
          "self",
          unpack(call[2])
        }
      }
    end
  end
  for _index_0 = 1, #chain_tail do
    local item = chain_tail[_index_0]
    insert(new_chain, item)
  end
  return new_chain
end
local super_scope
super_scope = function(value, t, key)
  local prev_method
  return {
    "scoped",
    Run(function(self)
      prev_method = self:get("current_method")
      self:set("current_method", key)
      return self:set("super", t)
    end),
    value,
    Run(function(self)
      return self:set("current_method", prev_method)
    end)
  }
end
return function(self, node, ret, parent_assign)
  local name, parent_val, body = unpack(node, 2)
  if parent_val == "" then
    parent_val = nil
  end
  local parent_cls_name = NameProxy("parent")
  local base_name = NameProxy("base")
  local self_name = NameProxy("self")
  local cls_name = NameProxy("class")
  local cls_instance_super
  cls_instance_super = function(...)
    return transform_super(cls_name, true, ...)
  end
  local cls_super
  cls_super = function(...)
    return transform_super(cls_name, false, ...)
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
          local k, v
          k, v = tuple[1], tuple[2]
          v = super_scope(v, cls_super, {
            "key_literal",
            k[2]
          })
          insert(statements, build.assign_one(k, v))
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
        if key[1] == "key_literal" and key[2] == CONSTRUCTOR_NAME then
          constructor = tuple[2]
          _continue_0 = true
          break
        else
          local val
          key, val = tuple[1], tuple[2]
          _value_0 = {
            key,
            super_scope(val, cls_instance_super, key)
          }
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
    local name_t = type(real_name)
    local flattened_name
    if name_t == "string" then
      flattened_name = real_name
    elseif name_t == "table" and real_name[1] == "ref" then
      flattened_name = real_name[2]
    else
      flattened_name = error("don't know how to extract name from " .. tostring(name_t))
    end
    real_name = {
      "string",
      '"',
      flattened_name
    }
  end
  local cls = build.table({
    {
      "__init",
      super_scope(constructor, cls_super, {
        "key_literal",
        "__init"
      })
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
        {
          "ref",
          "val"
        },
        "==",
        "nil"
      },
      ["then"] = {
        build.assign_one(LocalName("parent"), build.chain({
          base = "rawget",
          {
            "call",
            {
              {
                "ref",
                "cls"
              },
              {
                "string",
                '"',
                "__parent"
              }
            }
          }
        })),
        build["if"]({
          cond = LocalName("parent"),
          ["then"] = {
            build.chain({
              base = LocalName("parent"),
              {
                "index",
                "name"
              }
            })
          }
        })
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
              {
                "ref",
                "name"
              }
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
          return self:put_name(name)
        end
      end),
      {
        "declare",
        {
          cls_name
        }
      },
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
