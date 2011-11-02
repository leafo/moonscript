
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

