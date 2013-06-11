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
_ = (function()
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
      local _len_0 = 1
      for i, a in ipairs(x) do
        _accum_0[_len_0] = a * i
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)())
    _tbl_0[_key_0] = _val_0
  end
  return _tbl_0
end)()
local n1 = { }
local _len_0 = 1
for i = 1, 10 do
  n1[_len_0] = i
  _len_0 = _len_0 + 1
end
local n2 = { }
local _len_1 = 1
for i = 1, 10 do
  if i % 2 == 1 then
    n2[_len_1] = i
    _len_1 = _len_1 + 1
  end
end
local aa = { }
local _len_2 = 1
for x = 1, 10 do
  for y = 5, 14 do
    aa[_len_2] = {
      x,
      y
    }
    _len_2 = _len_2 + 1
  end
end
local bb = { }
local _len_3 = 1
for thing in y do
  for i = 1, 10 do
    bb[_len_3] = y
    _len_3 = _len_3 + 1
  end
end
local cc = { }
local _len_4 = 1
for i = 1, 10 do
  for thing in y do
    cc[_len_4] = y
    _len_4 = _len_4 + 1
  end
end
local dd = { }
local _len_5 = 1
for i = 1, 10 do
  if cool then
    for thing in y do
      if x > 3 then
        if c + 3 then
          dd[_len_5] = y
          _len_5 = _len_5 + 1
        end
      end
    end
  end
end
_ = (function()
  local _tbl_0 = { }
  for i = 1, 10 do
    _tbl_0["hello"] = "world"
  end
  return _tbl_0
end)()
return nil