
-- binary ops
x = 1 + 3

y = 1 +
  3

z = 1 +
  3 +
  4

--

k = b and c and
  g


h = thing and
  ->
    print "hello world"

-- TODO: should fail, indent still set to previous line so it thinks body is
-- indented
i = thing or
  ->
  print "hello world"

p = thing and
  ->
print "hello world"

s = thing or
  -> and 234


--
u = {
  color: 1 and 2 and
    3
    4
  4
}

v = {
  color: 1 and
    ->
      "yeah"
    "great"
  oksy: 3 ^
2
}

-- parens

nno = (
  yeah + 2   )

nn = (
  yeah + 2
)

n = hello(
  b
) ->

hello a,
  (
    yeah +
      2
  ) -
    okay

