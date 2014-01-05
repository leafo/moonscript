
hello = "hello"
world = "world"

(using nil) ->
  hello = 3223

(a using nil) ->
  hello = 3223
  a = 323

(a,b,c using a,b,c) ->
  a,b,c = 1,2,3
  world = 12321

(a,e,f using a,b,c, hello) ->
  a,b,c = 1,2,3
  hello = 12321
  world = "yeah"


