
local a
local a,b,c


x = 1212
something = ->
  local x
  x = 1212


do
  local *
  y = 2323
  z = 2323

do
  local *
  print "Nothing Here!"

do
  local ^
  x = 3434
  y = 3434
  X = 3434
  Y = "yeah"

do
  local ^
  x,y = "a", "b"

do
  local *
  x,y = "a", "b"


do
  local *
  if something
    x = 2323

-- this is broken
do
  local *
  do
    x = "one"

  x = 100

  do
    x = "two"

