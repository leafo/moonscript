local hello = "hello"
local world = "world"
local _
_ = function()
  local hello = 3223
end
_ = function(a)
  local hello = 3223
  a = 323
end
_ = function(a, b, c)
  a, b, c = 1, 2, 3
  local world = 12321
end
return function(a, e, f)
  local b, c
  a, b, c = 1, 2, 3
  hello = 12321
  local world = "yeah"
end