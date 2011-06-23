module "moonscript.compile", package.seeall

util = require "moonscript.util"
data = require "moonscript.data"

import itwos from util
import Set, ntype from data
import concat, insert from table

export indent_char, pretty, returner, moonlib, cascading, non_atomic, has_value, is_non_atomic

indent_char = "  "
pretty = (lines, indent) ->
  indent = indent or ""
  render = (line) ->
    if type(line) == "table"
      indent_char..pretty(line, indent..indent_char)
    else
      line

  lines = [render line for line in *lines]

  -- add semicolons for ambiguities
  fix = (i, left, k, right) ->
    if left\sub(-1) == ")" and right\sub(1,1) == "("
      lines[i] = lines[i]..";"
  fix(i,l, k,r) for i,l,k,r in itwos lines

  concat lines, "\n"..indent

returner = (exp) ->
  if ntype(exp) == "chain" and exp[2] == "return"
    -- extract the return
    items = {"explist"}
    insert items, v for v in *exp[3][2]
    {"return", items}
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
