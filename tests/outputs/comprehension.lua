local items = {
  1,
  2,
  3,
  4,
  5,
  6
}
local out = (function()
  local _tbl_0 = { }
  for k in items do
    _tbl_0[k] = k * 2
  end
  return _tbl_0
end)()
local x = {
  hello = "world",
  okay = 2323
}
local copy = (function()
  local _tbl_0 = { }
  for k, v in pairs(x) do
    if k ~= "okay" then
      _tbl_0[k] = v
    end
  end
  return _tbl_0
end)()
local _ = (function()
  local _tbl_0 = { }
  for x in yes do
    local _key_0, _val_0 = unpack(x)
    _tbl_0[_key_0] = _val_0
  end
  return _tbl_0
end)()
_ = (function()
  local _tbl_0 = { }
  local _list_0 = yes
  for _index_0 = 1, #_list_0 do
    x = _list_0[_index_0]
    local _key_0, _val_0 = unpack(x)
    _tbl_0[_key_0] = _val_0
  end
  return _tbl_0
end)()
_ = (function()
  local _tbl_0 = { }
  for x in yes do
    local _key_0, _val_0 = xxxx
    _tbl_0[_key_0] = _val_0
  end
  return _tbl_0
end)()
return (function()
  local _tbl_0 = { }
  local _list_0 = {
    {
      1,
      2
    },
    {
      3,
      4
    }
  }
  for _index_0 = 1, #_list_0 do
    x = _list_0[_index_0]
    local _key_0, _val_0 = unpack((function()
      local _accum_0 = { }
      local _len_0 = 0
      for i, a in ipairs(x) do
        _len_0 = _len_0 + 1
        _accum_0[_len_0] = a * i
      end
      return _accum_0
    end)())
    _tbl_0[_key_0] = _val_0
  end
  return _tbl_0
end)()