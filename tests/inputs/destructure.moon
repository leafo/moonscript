
{a, b} = hello

{{a}, b, {c}} = hello

{ :hello, :world } = value

{ yes: no, thing } = world

{:a,:b,:c,:d} = yeah

{a} = one, two
{b}, c = one
{d}, e = one, two

x, {y} = one, two

xx, yy = 1, 2
{yy, xx} = {xx, yy}

{a, :b, c, :d, e, :f, g} = tbl

--- 

futurists =
  sculptor: "Umberto Boccioni"
  painter:  "Vladimir Burliuk"
  poet:
    name:   "F.T. Marinetti"
    address: {
      "Via Roma 42R"
      "Bellagio, Italy 22021"
    }

{poet: {:name, address: {street, city}}} = futurists

print name, street, city

--

{ @world } = x
{ a.b, c.y, func!.z } = x

{ world: @world } = x

--

thing = {{1,2}, {3,4}}

for {x,y} in *thing
  print x,y


