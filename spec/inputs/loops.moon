
for x=1,10
  print "yeah"

for x=1,#something
  print "yeah"

for y=100,60,-3
  print "count down", y

for a=1,10 do print "okay"

for a=1,10
  for b = 2,43
    print a,b

for i in iter
  for j in yeah
    x = 343 + i + j
    print i, j

for x in *something
  print x

for k,v in pairs hello do print k,v

for x in y, z
  print x

for x in y, z, k
  print x


x = ->
  for x in y
    y

hello = {1,2,3,4,5}

x = for y in *hello
  if y % 2 == 0
    y

x = ->
  for x in *hello
    y

t = for i=10,20 do i * 2

hmm = 0
y = for j = 3,30, 8
  hmm += 1
  j * hmm

->
  for k=10,40
    "okay"

->
  return for k=10,40
    "okay"

while true do print "name"

while 5 + 5
  print "okay world"
  working man

while also do
  i work too
  "okay"

i = 0
x = while i < 10
  i += 1

-- values that can'e be coerced

x = for thing in *3
  y = "hello"

x = for x=1,2
  y = "hello"


-- continue

while true
  continue if false
  print "yes"
  break if true
  print "no"


for x=1,10
  continue if x > 3 and x < 7
  print x


list = for x=1,10
  continue if x > 3 and x < 7
  x


for a in *{1,2,3,4,5,6}
  continue if a == 1
  continue if a == 3
  print a



for x=1,10
  continue if x % 2 == 0
  for y = 2,12
    continue if y % 3 == 0


while true
  continue if false
  break

while true
  continue if false
  return 22

--

do
  xxx = {1,2,3,4}
  for thing in *xxx
    print thing


