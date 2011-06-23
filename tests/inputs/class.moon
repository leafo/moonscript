
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


