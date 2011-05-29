
hi = [x*2 for _, x in ipairs{1,2,3,4}]

items = {1,2,3,4,5,6}

mm = [@x for @x in ipairs items]

[z for z in ipairs items when z > 4]

rad = [{a} for a in ipairs {
   1,2,3,4,5,6,
} when good_number a]


[z for z in items for j in list when z > 4]

require "util"

dump = (x) -> print util.dump x

range = (count) ->
  i = 0
  return coroutine.wrap ->
    while i < count
      coroutine.yield i
      i = i + 1

dump [x for x in range 10]
dump [{x, y} for x in range 5 when x > 2 for y in range 5]

things = [x + y for x in range 10 when x > 5 for y in range 10 when y > 7]

print x,y for x in ipairs{1,2,4} for y in ipairs{1,2,3} when x != 2

print "hello", x for x in items

[x for x in x]
x = [x for x in x]

print x,y for x in ipairs{1,2,4} for y in ipairs{1,2,3} when x != 2

