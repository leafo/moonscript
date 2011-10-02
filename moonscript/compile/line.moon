module "moonscript.compile", package.seeall

util = require "moonscript.util"

require "moonscript.compile.format"
dump = require "moonscript.dump"

import reversed from util
import ntype, smart_node from require "moonscript.types"
import concat, insert from table

export line_compile

constructor_name = "new"

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

    -- todo: tree transformation
    if #values == 1 and @is_stm(values[1]) and cascading[ntype(values[1])]
      stm = values[1]
      @add declare if #undeclared > 0
      decorate = (value) ->
        {"assign", names, {value}}

      @stm stm, decorate
    else
      has_fndef = false
      i = 1
      while i <= #values
        if ntype(values[i]) == "fndef"
          has_fndef = true
        i = i +1

      with @line!
        skip_values = false
        if #undeclared == #names and not has_fndef
          \append declare
          skip_values = true if #values == 0
        else
          @add declare if #undeclared > 0
          \append_list [@value name for name in *names], ", "

        if not skip_values
          \append " = "
          \append_list [@value v for v in *values], ", "

  update: (node) =>
    _, name, op, exp = unpack node
    op_final = op\match "^(.+)=$"
    error "Unknown op: "..op if not op_final
    @stm {"assign", {name}, {{"exp", name, op_final, exp}}}

  return: (node) =>
    @line "return ", if node[2] != "" then @value node[2]

  break: (node) =>
    "break"

  import: (node) =>
    _, names, source = unpack node

    final_names, to_bind = {}, {}
    for name in *names
      final = if ntype(name) == ":"
        tmp = @name name[2]
        to_bind[tmp] = true
        tmp
      else
        @name name

      @put_name final
      insert final_names, final

    get_value = (name) ->
      if to_bind[name]
        moonlib.bind source, name
      else
        source.."."..name

    -- from constant expression, put it on one line
    if type(source) == "string"
      values = [get_value name for name in *final_names]
      line = with @line "local ", concat(final_names, ", "), " = "
        \append_list values, ", "
      return line

    @add @line "local ", concat(final_names, ", ")
    with @block "do"
      source = \init_free_var "table", source
      \stm {"assign", {name}, {get_value name}} for name in *final_names

  if: (node, ret) =>
    cond, block = node[2], node[3]
    root = with @block @line "if ", @value(cond), " then"
      \stms block, ret

    current = root
    add_clause = (clause)->
      type = clause[1]
      i = 2
      next = if type == "else"
        @block "else"
      else
        i += 1
        @block @line "elseif ", @value(clause[2]), " then"

      next\stms clause[i], ret

      current.next = next
      current = next

    add_clause cond for cond in *node[4:]
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

    if ntype(exp) == "unpack"
      iter = exp[2]
      loop = with @block!
        items_tmp = \free_name "item", true
        -- handle unpacked slices directly
        bounds = if is_slice iter
          slice = iter[#iter]
          table.remove iter
          table.remove slice, 1

          slice[2] = if slice[2] and slice[2] != ""
            max_tmp = \init_free_var "max", slice[2]
            {"exp", max_tmp, "<", 0
              "and", {"length", items_tmp}, "+", max_tmp
              "or", max_tmp }
          else
            {"length", items_tmp}

          slice
        else
          {1, {"length", items_tmp}}

        index_tmp = \free_name "index"

        \stm {"assign", {items_tmp}, {iter}}

        block = [s for s in *block]
        \shadow_name name for name in *names
        insert block, 1, {"assign", names, {
          {"chain", items_tmp, {"index", index_tmp}}
        }}

        \stm {"for", index_tmp, bounds, block }

      return loop

    loop = with @line!
      \append "for "
      \append_list [@name name for name in *names], ", "
      \append " in ", @value(exp), " do"

    with @block loop
      \stms block

  export: (node) =>
    _, names = unpack node
    @declare names
    nil

  comprehension: (node, action) =>
    _, exp, clauses = unpack node

    if not action
      action = (exp) -> {exp}

    current_stms = action exp
    for _, clause in reversed clauses
      t = clause[1]
      current_stms = if t == "for"
        _, names, iter = unpack clause
        {"foreach", names, iter, current_stms}
      elseif t == "when"
        _, cond = unpack clause
        {"if", cond, current_stms}
      else
        error "Unknown comprehension clause: "..t
      current_stms = {current_stms}

    @stms current_stms


  with: (node, ret) =>
    _, exp, block = unpack node

    with @block!
      var = \init_free_var "with", exp
      @set "scope_var", var
      \stms block
      \stm ret var if ret

  run: (code) =>
    code\call self
    nil

  group: (node) =>
    @stms node[2]

