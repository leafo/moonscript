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
  local items
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #op do
      local item = op[_index_0]
      _accum_0[_len_0] = flat_value(item, depth + 1)
      _len_0 = _len_0 + 1
    end
    items = _accum_0
  end
  local pos = op[-1]
  return "{" .. (pos and "[" .. pos .. "] " or "") .. table.concat(items, ", ") .. "}"
end
local value
value = function(op)
  return flat_value(op)
end
local tree
tree = function(block)
  return table.concat((function()
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #block do
      local value = block[_index_0]
      _accum_0[_len_0] = flat_value(value)
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)(), "\n")
end
return {
  value = value,
  tree = tree
}
