
import ntype from require "moonscript.types"
import concat, insert from table

import unpack from require "moonscript.util"

{
  raw: (node) => @add node[2]

  lines: (node) =>
    for line in *node[2]
      @add line

  declare: (node) =>
    names = node[2]
    undeclared = @declare names
    if #undeclared > 0
      with @line "local "
        \append_list [@name name for name in *undeclared], ", "

  -- this overrides the existing names with new locals, used for local keyword
  declare_with_shadows: (node) =>
    names = node[2]
    @declare names
    with @line "local "
      \append_list [@name name for name in *names], ", "

  assign: (node) =>
    names, values = unpack node, 2

    undeclared = @declare names
    declare = "local " .. concat(undeclared, ", ")

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
        @add declare, node[-1] if #undeclared > 0
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

  repeat: (node) =>
    cond, block = unpack node, 2
    with @block "repeat", @line "until ", @value cond
      \stms block

  while: (node) =>
    cond, block = unpack node, 2
    with @block @line "while ", @value(cond), " do"
      \stms block

  for: (node) =>
    name, bounds, block = unpack node, 2
    loop = @line "for ", @name(name), " = ", @value({"explist", unpack bounds}), " do"
    with @block loop
      \declare {name}
      \stms block

  -- for x in y ...
  -- {"foreach", {names...}, {exp...}, body}
  foreach: (node) =>
    names, exps, block = unpack node, 2

    loop = with @line!
      \append "for "

    with @block loop
      loop\append_list [\name name, false for name in *names], ", "
      loop\append " in "
      loop\append_list [@value exp for exp in *exps], ","
      loop\append " do"

      \declare names
      \stms block

  export: (node) =>
    names = unpack node, 2
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

  noop: => -- nothing!
}
