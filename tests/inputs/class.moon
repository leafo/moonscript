
class Hello
  new: (@test, @world) =>
    print "creating object.."
  hello: =>
    print @test, @world
  __tostring: => "hello world"

x = Hello 1,2
x\hello()

print x

class Simple
  cool: => print "cool"

class Yikes extends Simple
  new: => print "created hello"

x = Yikes()
x\cool()


class Hi
  new: (arg) =>
    print "init arg", arg

  cool: (num) =>
    print "num", num


class Simple extends Hi
  new: => super "man"
  cool: => super 120302

x = Simple()
x\cool()

print x.__class == Simple


class Okay
  -- what is going on
  something: 20323
  -- yeaha


class Biggie extends Okay
  something: =>
    super 1,2,3,4
    super.something another_self, 1,2,3,4
    assert super == Okay


class Yeah
  okay: =>
    super\something 1,2,3,4


class What
  something: => print "val:", @val

class Hello extends What
  val: 2323
  something: => super\something

with Hello!
  x = \something!
  print x
  x!

class CoolSuper
  hi: =>
    super(1,2,3,4) 1,2,3,4
    super.something 1,2,3,4
    super.something(1,2,3,4).world
    super\yeah"world".okay hi, hi, hi
    something.super
    super.super.super.super
    nil


-- selfing
x = @hello
x = @@hello

@hello "world"
@@hello "world"

@@one @@two(4,5) @three, @four

xx = (@hello, @@world, cool) ->


-- class properties
class ClassMan
  @yeah: 343
  blue: =>
  @hello: 3434, @world: 23423
  green: =>
  @red: =>


x = @
y = @@

@ something

@@ something

@ = @ + @ / @

@ = 343
@.hello 2,3,4

hello[@].world


class Whacko
  @hello
  if something
    print "hello world"

  hello = "world"
  @another = "day"

  print "yeah" if something -- this is briken


print "hello"


