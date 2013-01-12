local ntype, mtype, build
do
  local _table_0 = require("moonscript.types")
  ntype, mtype, build = _table_0.ntype, _table_0.mtype, _table_0.build
end
local NameProxy
do
  local _table_0 = require("moonscript.transform.names")
  NameProxy = _table_0.NameProxy
end
local insert = table.insert
local unpack
do
  local _table_0 = require("moonscript.util")
  unpack = _table_0.unpack
end
local user_error
do
  local _table_0 = require("moonscript.errors")
  user_error = _table_0.user_error
end
local join
join = function(...)
  do
    local _with_0 = { }
    local out = _with_0
    local i = 1
    local _list_0 = {
      ...
    }
    for _index_0 = 1, #_list_0 do
      local tbl = _list_0[_index_0]
      local _list_1 = tbl
      for _index_1 = 1, #_list_1 do
        local v = _list_1[_index_1]
        out[i] = v
        i = i + 1
      end
    end
    return _with_0
  end
end
local has_destructure
has_destructure = function(names)
  local _list_0 = names
  for _index_0 = 1, #_list_0 do
    local n = _list_0[_index_0]
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
        s = {
          "dot",
          key[2]
        }
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
    local t = ntype(value)
    if t == "value" or t == "chain" or t == "self" then
      insert(accum, {
        value,
        suffix
      })
    elseif t == "table" then
      extract_assign_names(value, accum, suffix)
    else
      user_error("Can't destructure value of type: " .. tostring(ntype(value)))
    end
  end
  return accum
end
local build_assign
build_assign = function(destruct_literal, receiver)
  local extracted_names = extract_assign_names(destruct_literal)
  local names = { }
  local values = { }
  local inner = {
    "assign",
    names,
    values
  }
  local obj
  if mtype(receiver) == NameProxy then
    obj = receiver
  else
    do
      local _with_0 = NameProxy("obj")
      obj = _with_0
      inner = build["do"]({
        build.assign_one(obj, receiver),
        {
          "assign",
          names,
          values
        }
      })
      obj = _with_0
    end
  end
  local _list_0 = extracted_names
  for _index_0 = 1, #_list_0 do
    local tuple = _list_0[_index_0]
    insert(names, tuple[1])
    insert(values, obj:chain(unpack(tuple[2])))
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
split_assign = function(assign)
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
      insert(g, build_assign(n, values[i]))
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
      name_slice = (function()
        local _accum_0 = { }
        local _len_0 = 1
        for i = start, total_names do
          _accum_0[_len_0] = names[i]
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)()
    end
    local value_slice
    if total_values < start then
      value_slice = {
        "nil"
      }
    else
      value_slice = (function()
        local _accum_0 = { }
        local _len_0 = 1
        for i = start, total_values do
          _accum_0[_len_0] = values[i]
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)()
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
