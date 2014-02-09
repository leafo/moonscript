-- testing `return` propagation

-> x for x in *things
-> [x for x in *things]


-- doesn't make sense on purpose
do
  return x for x in *things

do
  return [x for x in *things]

do
  return {x,y for x,y in *things}

->
  if a
    if a
      a
    else
      b
  elseif b
    if a
      a
    else
      b
  else
    if a
      a
    else
      b


do
  return if a
    if a
      a
    else
      b
  elseif b
    if a
      a
    else
      b
  else
    if a
      a
    else
      b

-> a\b
do a\b


