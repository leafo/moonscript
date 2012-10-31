module("moonscript.util", package.seeall)
local concat = table.concat
moon = {
  is_object = function(value)
    return type(value) == "table" and value.__class
  end,
  type = function(value)
    local base_type = type(value)
    if base_type == "table" then
      local cls = value.__class
      if cls then
        return cls
      end
    end
    return base_type
  end
}
pos_to_line = function(str, pos)
  local line = 1
  for _ in str:sub(1, pos):gmatch("\n") do
    line = line + 1
  end
  return line
end
get_closest_line = function(str, line_num)
  local line = get_line(str, line_num)
  if (not line or trim(line) == "") and line_num > 1 then
    return get_closest_line(str, line_num - 1)
  else
    return line, line_num
  end
end
get_line = function(str, line_num)
  for line in str:gmatch("([^\n]*)\n?") do
    if line_num == 1 then
      return line
    end
    line_num = line_num - 1
  end
end
reversed = function(seq)
  return coroutine.wrap(function()
    for i = #seq, 1, -1 do
      coroutine.yield(i, seq[i])
    end
  end)
end
trim = function(str)
  return str:match("^%s*(.-)%s*$")
end
split = function(str, delim)
  if str == "" then
    return { }
  end
  str = str .. delim
  return (function()
    local _accum_0 = { }
    local _len_0 = 0
    for m in str:gmatch("(.-)" .. delim) do
      _len_0 = _len_0 + 1
      _accum_0[_len_0] = m
    end
    return _accum_0
  end)()
end
dump = function(what)
  local seen = { }
  local _dump
  _dump = function(what, depth)
    if depth == nil then
      depth = 0
    end
    local t = type(what)
    if t == "string" then
      return '"' .. what .. '"\n'
    elseif t == "table" then
      if seen[what] then
        return "recursion(" .. tostring(what) .. ")...\n"
      end
      seen[what] = true
      depth = depth + 1
      local lines = (function()
        local _accum_0 = { }
        local _len_0 = 0
        for k, v in pairs(what) do
          local _value_0 = (" "):rep(depth * 4) .. "[" .. tostring(k) .. "] = " .. _dump(v, depth)
          if _value_0 ~= nil then
            _len_0 = _len_0 + 1
            _accum_0[_len_0] = _value_0
          end
        end
        return _accum_0
      end)()
      seen[what] = false
      return "{\n" .. concat(lines) .. (" "):rep((depth - 1) * 4) .. "}\n"
    else
      return tostring(what) .. "\n"
    end
  end
  return _dump(what)
end
debug_posmap = function(posmap, moon_code, lua_code)
  local tuples = (function()
    local _accum_0 = { }
    local _len_0 = 0
    for k, v in pairs(posmap) do
      _len_0 = _len_0 + 1
      _accum_0[_len_0] = {
        k,
        v
      }
    end
    return _accum_0
  end)()
  table.sort(tuples, function(a, b)
    return a[1] < b[1]
  end)
  local lines = (function()
    local _accum_0 = { }
    local _len_0 = 0
    local _list_0 = tuples
    for _index_0 = 1, #_list_0 do
      local pair = _list_0[_index_0]
      local lua_line, pos = unpack(pair)
      local moon_line = pos_to_line(moon_code, pos)
      local lua_text = get_line(lua_code, lua_line)
      local moon_text = get_closest_line(moon_code, moon_line)
      local _value_0 = tostring(pos) .. "\t " .. tostring(lua_line) .. ":[ " .. tostring(trim(lua_text)) .. " ] >> " .. tostring(moon_line) .. ":[ " .. tostring(trim(moon_text)) .. " ]"
      if _value_0 ~= nil then
        _len_0 = _len_0 + 1
        _accum_0[_len_0] = _value_0
      end
    end
    return _accum_0
  end)()
  return concat(lines, "\n")
end
return nil
