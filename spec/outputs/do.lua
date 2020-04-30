do
  print("hello")
  print("world")
end
local x
do
  print("hello")
  x = print("world")
end
local y
do
  local things = "shhh"
  y = function()
    return "hello: " .. things
  end
end
local _
_ = function()
  if something then
    do
      return "yeah"
    end
  end
end
local t = {
  y = (function()
    local number = 100
    return function(x)
      return x + number
    end
  end)()
}
return function(y, k)
  if y == nil then
    y = ((function()
      x = 10 + 2
      return x
    end)())
  end
  if k == nil then
    do
      k = "nothing"
    end
  end
  do
    return "uhhh"
  end
end
