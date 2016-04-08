local items = {
  1,
  2,
  3,
  4,
  5,
  6
}
local out
do
  local _tbl_0 = { }
  for k in items do
    _tbl_0[k] = k * 2
  end
  out = _tbl_0
end
local x = {
  hello = "world",
  okay = 2323
}
local copy
do
  local _tbl_0 = { }
  for k, v in pairs(x) do
    if k ~= "okay" then
      _tbl_0[k] = v
    end
  end
  copy = _tbl_0
end
local _
do
  local _tbl_0 = { }
  for x in yes do
    local _key_0, _val_0 = unpack(x)
    _tbl_0[_key_0] = _val_0
  end
  _ = _tbl_0
end
do
  local _tbl_0 = { }
  local _list_0 = yes
  for _index_0 = 1, #_list_0 do
    local x = _list_0[_index_0]
    local _key_0, _val_0 = unpack(x)
    _tbl_0[_key_0] = _val_0
  end
  _ = _tbl_0
end
do
  local _tbl_0 = { }
  for x in yes do
    local _key_0, _val_0 = xxxx
    _tbl_0[_key_0] = _val_0
  end
  _ = _tbl_0
end
do
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
    local x = _list_0[_index_0]
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
  _ = _tbl_0
end
local n1
do
  local _accum_0 = { }
  local _len_0 = 1
  for i = 1, 10 do
    _accum_0[_len_0] = i
    _len_0 = _len_0 + 1
  end
  n1 = _accum_0
end
local n2
do
  local _accum_0 = { }
  local _len_0 = 1
  for i = 1, 10 do
    if i % 2 == 1 then
      _accum_0[_len_0] = i
      _len_0 = _len_0 + 1
    end
  end
  n2 = _accum_0
end
local aa
do
  local _accum_0 = { }
  local _len_0 = 1
  for x = 1, 10 do
    for y = 5, 14 do
      _accum_0[_len_0] = {
        x,
        y
      }
      _len_0 = _len_0 + 1
    end
  end
  aa = _accum_0
end
local bb
do
  local _accum_0 = { }
  local _len_0 = 1
  for thing in y do
    for i = 1, 10 do
      _accum_0[_len_0] = y
      _len_0 = _len_0 + 1
    end
  end
  bb = _accum_0
end
local cc
do
  local _accum_0 = { }
  local _len_0 = 1
  for i = 1, 10 do
    for thing in y do
      _accum_0[_len_0] = y
      _len_0 = _len_0 + 1
    end
  end
  cc = _accum_0
end
local dd
do
  local _accum_0 = { }
  local _len_0 = 1
  for i = 1, 10 do
    if cool then
      for thing in y do
        if x > 3 then
          if c + 3 then
            _accum_0[_len_0] = y
            _len_0 = _len_0 + 1
          end
        end
      end
    end
  end
  dd = _accum_0
end
do
  local _tbl_0 = { }
  for i = 1, 10 do
    _tbl_0["hello"] = "world"
  end
  _ = _tbl_0
end
return nil