
-- vararg bubbling
f = (...) -> #{...}

dont_bubble = ->
  [x for x in ((...)-> print ...)("hello")]

k = [x for x in ((...)-> print ...)("hello")]

j = for i=1,10
  (...) -> print ...

-- bubble me

m = (...) ->
  [x for x in *{...} when f(...) > 4]

x = for i in *{...} do i
y = [x for x in *{...}]
z = [x for x in hallo when f(...) > 4]


a = for i=1,10 do ...

b = for i=1,10
  -> print ...


