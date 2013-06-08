
do
  print "hello"
  print "world"

x = do
  print "hello"
  print "world"

y = do
  things = "shhh"
  -> "hello: " .. things

-> if something then do "yeah"

t = {
  y: do
    number = 100
    (x) -> x + number
}

(y=(do
  x = 10 + 2
  x), k=do
    "nothing") -> do
      "uhhh"

