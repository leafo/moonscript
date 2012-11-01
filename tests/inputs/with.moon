
a = ->
  with something
    print .hello
    print hi
    print "world"

with leaf
  .world!
  .world 1,2,3

  g = .what.is.this

  .hi 1,2,3

  \hi(1,2).world 2323

  \hi "yeah", "man"
  .world = 200

zyzyzy = with something
  .set_state "hello world"


x = 5 + with Something!
  \write "hello world"


x = {
  hello: with yeah
    \okay!
}

with foo
  \prop"something".hello
  .prop\send(one)
  .prop\send one


--

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




