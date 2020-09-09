class A
  new: (@v=0) =>
  inc: (val=1) => @@ @v+val
  dec: (val=1) => @@ @v-val
  val: => @v

a = A!
a \= inc 2
assert a.v == 2
a \= inc!
assert a.v == 3
a \= dec!
assert a.v == 2
a \= val!
assert a == 2
