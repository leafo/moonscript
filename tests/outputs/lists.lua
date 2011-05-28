local hi = (function()
  local tmp = {}
  for _, x in ipairs({
  1,
  2,
  3,
  4
}) do
    table.insert(tmp, x * 2)
  end
  return tmp
end)()
local items = {
  1,
  2,
  3,
  4,
  5,
  6
}
local mm = (function()
  local tmp = {}
  for self.x in ipairs(items) do
    table.insert(tmp, self.x)
  end
  return tmp
end)();
(function()
  local tmp = {}
  for z in ipairs(items) do
    if z > 4 then
      table.insert(tmp, z)
    end
  end
  return tmp
end)()
local rad = (function()
  local tmp = {}
  for a in ipairs({
  1,
  2,
  3,
  4,
  5,
  6
}) do
    if good_number(a) then
      table.insert(tmp, { a })
    end
  end
  return tmp
end)()