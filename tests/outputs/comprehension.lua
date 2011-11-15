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