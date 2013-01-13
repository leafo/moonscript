local a
local a, b, c
local x = 1212
local something
something = function()
  local x
  x = 1212
end
do
  local y, z
  y = 2323
  z = 2323
end
do
  
  print("Nothing Here!")
end
do
  local X, Y
  x = 3434
  local y = 3434
  X = 3434
  Y = "yeah"
end
do
  
  local y
  x, y = "a", "b"
end
do
  local x, y
  x, y = "a", "b"
end
do
  
  if something then
    x = 2323
  end
end
do
  local x
  do
    x = "one"
  end
  x = 100
  do
    x = "two"
  end
end