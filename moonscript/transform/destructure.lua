local ntype, mtype, build
do
  local _obj_0 = require("moonscript.types")
  ntype, mtype, build = _obj_0.ntype, _obj_0.mtype, _obj_0.build
end
local NameProxy
do
  local _obj_0 = require("moonscript.transform.names")
  NameProxy = _obj_0.NameProxy
end
local insert
do
  local _obj_0 = table
  insert = _obj_0.insert
end
local unpack
do
  local _obj_0 = require("moonscript.util")
  unpack = _obj_0.unpack
end
local user_error
do
  local _obj_0 = require("moonscript.errors")
  user_error = _obj_0.user_error
end
local join
join = function(...)
  do
    local out = { }
    local i = 1
    local _list_0 = {
      ...
    }
    for _index_0 = 1, #_list_0 do
      local tbl = _list_0[_index_0]
      for _index_1 = 1, #tbl do
        local v = tbl[_index_1]
        out[i] = v
        i = i + 1
      end
    end
    return out
  end
end
local has_destructure
has_destructure = function(names)
  for _index_0 = 1, #names do
    local n = names[_index_0]
    if ntype(n) == "table" then
      return true
    end
  end
  return false
end
local extract_assign_names
extract_assign_names = function(name, accum, prefix)
  if accum == nil then
    accum = { }
  end
  if prefix == nil then
    prefix = { }
  end
  local i = 1
  local _list_0 = name[2]
  for _index_0 = 1, #_list_0 do
    local tuple = _list_0[_index_0]
    local value, suffix
    if #tuple == 1 then
      local s = {
        "index",
        {
          "number",
          i
        }
      }
      i = i + 1
      value, suffix = tuple[1], s
    else
      local key = tuple[1]
      local s
      if ntype(key) == "key_literal" then
        local key_name = key[2]
        if ntype(key_name) == "colon_stub" then
          s = key_name
        else
          s = {
            "dot",
            key_name
          }
        end
      else
        s = {
          "index",
          key
        }
      end
      value, suffix = tuple[2], s
    end
    suffix = join(prefix, {
      suffix
    })
    local _exp_0 = ntype(value)
    if "value" == _exp_0 or "ref" == _exp_0 or "chain" == _exp_0 or "self" == _exp_0 then
      insert(accum, {
        value,
        suffix
      })
    elseif "table" == _exp_0 then
      extract_assign_names(value, accum, suffix)
    else
      user_error("Can't destructure value of type: " .. tostring(ntype(value)))
    end
  end
  return accum
end
local build_assign
build_assign = function(scope, destruct_literal, receiver)
  local extracted_names = extract_assign_names(destruct_literal)
  local names = { }
  local values = { }
  local inner = {
    "assign",
    names,
    values
  }
  local obj
  if scope:is_local(receiver) then
    obj = receiver
  else
    do
      obj = NameProxy("obj")
      inner = build["do"]({
        build.assign_one(obj, receiver),
        {
          "assign",
          names,
          values
        }
      })
      obj = obj
    end
  end
  for _index_0 = 1, #extracted_names do
    local tuple = extracted_names[_index_0]
    insert(names, tuple[1])
    insert(values, NameProxy.chain(obj, unpack(tuple[2])))
  end
  return build.group({
    {
      "declare",
      names
    },
    inner
  })
end
local split_assign
split_assign = function(scope, assign)
  local names, values = unpack(assign, 2)
  local g = { }
  local total_names = #names
  local total_values = #values
  local start = 1
  for i, n in ipairs(names) do
    if ntype(n) == "table" then
      if i > start then
        local stop = i - 1
        insert(g, {
          "assign",
          (function()
            local _accum_0 = { }
            local _len_0 = 1
            for i = start, stop do
              _accum_0[_len_0] = names[i]
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)(),
          (function()
            local _accum_0 = { }
            local _len_0 = 1
            for i = start, stop do
              _accum_0[_len_0] = values[i]
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)()
        })
      end
      insert(g, build_assign(scope, n, values[i]))
      start = i + 1
    end
  end
  if total_names >= start or total_values >= start then
    local name_slice
    if total_names < start then
      name_slice = {
        "_"
      }
    else
      do
        local _accum_0 = { }
        local _len_0 = 1
        for i = start, total_names do
          _accum_0[_len_0] = names[i]
          _len_0 = _len_0 + 1
        end
        name_slice = _accum_0
      end
    end
    local value_slice
    if total_values < start then
      value_slice = {
        "nil"
      }
    else
      do
        local _accum_0 = { }
        local _len_0 = 1
        for i = start, total_values do
          _accum_0[_len_0] = values[i]
          _len_0 = _len_0 + 1
        end
        value_slice = _accum_0
      end
    end
    insert(g, {
      "assign",
      name_slice,
      value_slice
    })
  end
  return build.group(g)
end
return {
  has_destructure = has_destructure,
  split_assign = split_assign,
  build_assign = build_assign
}
