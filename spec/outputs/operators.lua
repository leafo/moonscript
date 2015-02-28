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
local u = {
  color = 1 and 2 and 3,
  4,
  4
}
local v = {
  color = 1 and function()
    return "yeah"
  end,
  "great",
  oksy = 3 ^ 2
}
local nno = (yeah + 2)
local nn = (yeah + 2)
local n = hello(b)(function() end)
return hello(a, (yeah + 2) - okay)