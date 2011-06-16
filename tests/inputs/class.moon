
class Hello
  new: (@test, @world) =>
    print "creating object.."
  hello: =>
    print @test, @world
  __tostring: => "hello world"

x = Hello 1,2
x:hello()

print x

class Simple
  cool: => print "cool"

class Yikes extends Simple
  new: => print "created hello"

x = Yikes()
x:cool()

