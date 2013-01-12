local flat_value
flat_value = function(op, depth)
  if depth == nil then
    depth = 1
  end
  if type(op) == "string" then
    return '"' .. op .. '"'
  end
  if type(op) ~= "table" then
    return tostring(op)
  end
  local items = (function()
    local _accum_0 = { }
    local _len_0 = 1
    local _list_0 = op
    for _index_0 = 1, #_list_0 do
      local item = _list_0[_index_0]
      _accum_0[_len_0] = flat_value(item, depth + 1)
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)()
  local pos = op[-1]
  return "{" .. (pos and "[" .. pos .. "] " or "") .. table.concat(items, ", ") .. "}"
end
local value
value = function(op)
  return flat_value(op)
end
local tree
tree = function(block)
  local _list_0 = block
  for _index_0 = 1, #_list_0 do
    value = _list_0[_index_0]
    print(flat_value(value))
  end
end
return {
  value = value,
  tree = tree
}
