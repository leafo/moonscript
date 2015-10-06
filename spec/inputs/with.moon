
do
  a = ->
    with something
      print .hello
      print hi
      print "world"

do
  with leaf
    .world!
    .world 1,2,3

    g = .what.is.this

    .hi 1,2,3

    \hi(1,2).world 2323

    \hi "yeah", "man"
    .world = 200

do
  zyzyzy = with something
    .set_state "hello world"

do
  x = 5 + with Something!
    \write "hello world"


do
  x = {
    hello: with yeah
      \okay!
  }

do
  with foo
    \prop"something".hello
    .prop\send(one)
    .prop\send one


--

do
  with a, b -- b is lost
    print .world

  mod = with _M = {}
    .Thing = "hi"

  -- operate on a only
  with a, b = something, pooh
    print .world

  x = with a, b = 1, 2
    print a + b

  print with a, b = 1, 2
    print a + b

  -- assignment lhs must be evaluated in the order they appear
  p = with hello!.x, world!.y = 1, 2
    print a + b

--

do
  x = "hello"
  with x
    x\upper!

do
  with k = "jo"
    print \upper!

do
  with a,b,c = "", "", ""
    print \upper!

do
  a = "bunk"
  with a,b,c = "", "", ""
    print \upper!

do
  with j
    print \upper!

do
  with k.j = "jo"
    print \upper!

do
  with a
    print .b
    -- nested `with`s should change the scope correctly
    with .c
      print .d

do
  with a
    -- nested `with`s with assignments should change the scope correctly
    with .b = 2
      print .c

do
  ->
    with hi
      return .a, .b


do
  with dad
    .if "yes"
    y = .end.of.function
