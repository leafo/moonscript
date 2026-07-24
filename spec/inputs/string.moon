
hi = "hello"
hello = "what the heckyes"
print hi

umm = 'umm'

here, another = "yeah", 'world'

aye = "YU'M"
you '"hmmm" I said'

print aye, you

another = [[ hello world ]]


hi_there = [[
  hi there
]]

well = [==[ "helo" ]==]

hola = [===[
  eat noots]===]

mm = [[well trhere]]

oo = ""

x = "\\"
x = "a\\b"
x = "\\\n"
x = "\""

-- 

a = "hello #{hello} hello"
b = "#{hello} hello"
c = "hello #{5+1}"
d = "#{hello world}"
e = "#{1} #{2} #{3}"

f = [[hello #{world} world]]

--

a = 'hello #{hello} hello'
b = '#{hello} hello'
c = 'hello #{hello}'


--

"hello"
"hello"\format 1
"hello"\format(1,2,3)
"hello"\format(1,2,3) 1,2,3

"hello"\world!
"hello"\format!.hello 1,2,3
"hello"\format 1,2,3

something"hello"\world!
something "hello"\world!


-- interpolation keeps grouping next to tighter binding operators

x = 10 / "#{b}.5"

y = 1 + "#{n}0" * 2

cmp = a == "v#{b}"

joined = "a" .. "b#{c}"

mixed = "#{a}b" * 2 - "c#{d}"
