
do
  {a, b} = hello

  {{a}, b, {c}} = hello

  { :hello, :world } = value

do
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

do
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

--

do
  { @world } = x
  { a.b, c.y, func!.z } = x

  { world: @world } = x

--

do
  thing = {{1,2}, {3,4}}

  for {x,y} in *thing
    print x,y


--

do
  with {a,b} = thing
    print a, b


--

do
  thing = nil
  if {a} = thing
    print a
  else
    print "nothing"

  thang = {1,2}
  if {a,b} = thang
    print a,b

  if {a,b} = thing
    print a,b
  elseif {c,d} = thang
    print c,d
  else
    print "NO"

--

do
  z = "yeah"
  {a,b,c} = z

do
  {a,b,c} = z

(z) ->
  {a,b,c} = z

do
  z = "oo"
  (k) ->
    {a,b,c} = z


-- destructuring against expression blocks

{a, b} = for i in *{2, 3} do i * i

{c, d} = [v * 2 for v in *{1, 2}]

{:left, :right} = if cond then {left: 1, right: 2} else {left: 3}

{p, q} = do
  {10, 20}

{:val} = switch x
  when 2 then {val: "two"}

{t} = with something! do .x = 5

{u, v} = {7, 8} if cond

n, {:m} = if cond then 1, {m: 2}

{:k} = {w, true for w in thing\gmatch "%w"}

{a: {inner}} = if cond then {a: {"deep"}}

{lit} = {42}

{:single} = if cond then {single: 1}, {single: 2}

-- receivers that can't be chained directly

grab = (...) ->
  {:first_arg} = ...

{nothing} = nil

{:negated} = not thing

{:len} = #thing
