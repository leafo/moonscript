local x = 1 + 3
local y = 1 + 3
local z = 1 + 3 + 4
local k = b and c and g
local h = thing and function()
  return print("hello world")
end
local i = thing or function()
  return print("hello world")
end
local p = thing and function() end
print("hello world")
local s = thing or function() end and 234