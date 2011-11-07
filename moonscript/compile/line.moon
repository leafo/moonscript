module "moonscript.compile", package.seeall

util = require "moonscript.util"

require "moonscript.compile.format"
dump = require "moonscript.dump"

import reversed from util
import ntype from require "moonscript.types"
import concat, insert from table

export line_compile

line_compile =
  raw: (node) =>
    _, text = unpack node
    @add text

  declare: (node) =>
    _, names = unpack node
    undeclared = @declare names
    if #undeclared > 0
      with @line "local "
        \append_list [@name name for name in *names], ", "

  assign: (node) =>
    _, names, values = unpack node

    undeclared = @declare names
    declare = "local "..concat(undeclared, ", ")

    has_fndef = false
    i = 1
    while i <= #values
      if ntype(values[i]) == "fndef"
        has_fndef = true
      i = i +1

    with @line!
      if #undeclared == #names and not has_fndef
        \append declare
      else
        @add declare if #undeclared > 0
        \append_list [@value name for name in *names], ", "

      \append " = "
      \append_list [@value v for v in *values], ", "

  return: (node) =>
    @line "return ", if node[2] != "" then @value node[2]

  break: (node) =>
    "break"

  if: (node) =>
    cond, block = node[2], node[3]
    root = with @block @line "if ", @value(cond), " then"
      \stms block

    current = root
    add_clause = (clause)->
      type = clause[1]
      i = 2
      next = if type == "else"
        @block "else"
      else
        i += 1
        @block @line "elseif ", @value(clause[2]), " then"

      next\stms clause[i]

      current.next = next
      current = next

    add_clause cond for cond in *node[4,]
    root

  while: (node) =>
    _, cond, block = unpack node

    out = if is_non_atomic cond
      with @block "while true do"
        \stm {"if", {"not", cond}, {{"break"}}}
    else
      @block @line "while ", @value(cond), " do"

    out\stms block
    out

  for: (node) =>
    _, name, bounds, block = unpack node
    loop = @line "for ", @name(name), " = ", @value({"explist", unpack bounds}), " do"
    with @block loop
      \stms block

  -- for x in y ...
  -- {"foreach", {names...}, exp, body}
  foreach: (node) =>
    _, names, exp, block = unpack node

    loop = with @line!
      \append "for "
      \append_list [@name name for name in *names], ", "
      \append " in ", @value(exp), " do"

    with @block loop
      \stms block

  export: (node) =>
    _, names = unpack node
    if type(names) == "string"
      if names == "*"
        @export_all = true
      elseif names == "^"
        @export_proper = true
    else
      @declare names
    nil

  run: (code) =>
    code\call self
    nil

  group: (node) =>
    @stms node[2]

  do: (node) =>
    with @block!
      \stms node[2]

