local _
_ = function()
  local _list_0 = things
  for _index_0 = 1, #_list_0 do
    local x = _list_0[_index_0]
    _ = x
  end
end
_ = function()
  local _accum_0 = { }
  local _len_0 = 1
  local _list_0 = things
  for _index_0 = 1, #_list_0 do
    local x = _list_0[_index_0]
    _accum_0[_len_0] = x
    _len_0 = _len_0 + 1
  end
  return _accum_0
end
do
  local _list_0 = things
  for _index_0 = 1, #_list_0 do
    local x = _list_0[_index_0]
    return x
  end
end
do
  local _accum_0 = { }
  local _len_0 = 1
  local _list_0 = things
  for _index_0 = 1, #_list_0 do
    local x = _list_0[_index_0]
    _accum_0[_len_0] = x
    _len_0 = _len_0 + 1
  end
  return _accum_0
end
do
  local _tbl_0 = { }
  local _list_0 = things
  for _index_0 = 1, #_list_0 do
    local x, y = _list_0[_index_0]
    _tbl_0[x] = y
  end
  return _tbl_0
end
_ = function()
  if a then
    if a then
      return a
    else
      return b
    end
  elseif b then
    if a then
      return a
    else
      return b
    end
  else
    if a then
      return a
    else
      return b
    end
  end
end
do
  if a then
    if a then
      return a
    else
      return b
    end
  elseif b then
    if a then
      return a
    else
      return b
    end
  else
    if a then
      return a
    else
      return b
    end
  end
end
_ = function()
  local _base_0 = a
  local _fn_0 = _base_0.b
  return function(...)
    return _fn_0(_base_0, ...)
  end
end
do
  local _base_0 = a
  local _fn_0 = _base_0.b
  return function(...)
    return _fn_0(_base_0, ...)
  end
end