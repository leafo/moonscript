

import hello from yeah
import hello, world from table["cool"]

import a, \b, c from items


import master, \ghost from find "mytable"


a, yumm = 3434, "hello"


_table_0 = 232

import something from a table


if indent
  import okay, \well from tables[100]

do
  import a, b, c from z

do
  import a,
    b, c from z

do
  import a
    b
    c from z

do
  import
    a
    b
    c from z


do
  import
    a
    b
    c
    from z



-- import name is hoisted by local *
do
  local *
  use = -> insert "hello"
  import insert from table

-- import inside class body is hoisted for methods
class Pipeline
  import insert from table

  add: (...) => insert @, ...
