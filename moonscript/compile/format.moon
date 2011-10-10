module "moonscript.compile", package.seeall

util = require "moonscript.util"
data = require "moonscript.data"

import Set from require "moonscript.data"
import ntype from require "moonscript.types"
import concat, insert from table

export indent_char, default_return, moonlib, cascading, non_atomic, has_value, is_non_atomic
export count_lines, user_error

indent_char = "  "

user_error = (...) ->
  error {"user-error", ...}

manual_return = Set{"foreach", "for", "while"}

default_return = (exp) ->
  t = ntype exp
  if t == "chain" and exp[2] == "return"
    -- extract the return
    items = {"explist"}
    insert items, v for v in *exp[3][2]
    {"return", items}
  elseif manual_return[t]
    exp
  else
    {"return", exp}

moonlib =
  bind: (tbl, name) ->
    concat {"moon.bind(", tbl, ".", name, ", ", tbl, ")"}

cascading = Set{ "if", "with" }

-- an action that can't be completed in a single line
non_atomic = Set{ "update" }

-- does this always return a value
has_value = (node) ->
  if ntype(node) == "chain"
    ctype = ntype(node[#node])
    ctype != "call" and ctype != "colon"
  else
    true

is_non_atomic = (node) ->
  non_atomic[ntype(node)]

count_lines = (str) ->
  count = 1
  count += 1 for _ in str\gmatch "\n"
  count

