
-- see lists.moon for list comprehension tests

items = {1,2,3,4,5,6}
out = {k,k*2 for k in items}


x = hello: "world", okay: 2323

copy  = {k,v for k,v in pairs x when k != "okay"}

--

{ unpack(x) for x in yes }
{ unpack(x) for x in *yes }

{ xxxx for x in yes }
{ unpack [a*i for i, a in ipairs x] for x in *{{1,2}, {3,4}} }

