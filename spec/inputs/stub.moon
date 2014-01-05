

x = {
  val: 100
  hello: =>
    print @val
}

fn = x\val
print fn!
print x\val!


-- ... should be bubbled up anon functions
x = hello(...)\world

