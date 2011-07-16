
module "moonscript.compile", package.seeall

util = require "moonscript.util"
data = require "moonscript.data"
dump = require "moonscript.dump"

require "moonscript.compile.format"

import ntype from data
import concat, insert from table

export value_compile

value_compile =
  exp: (node) =>
    _comp = (i, value) ->
      if i % 2 == 1 and value == "!="
        value = "~="
      @value value

    with @line!
      \append_list [_comp i,v for i,v in ipairs node when i > 1], " "

  update: (node) =>
    _, name = unpack node
    @stm node
    @name name

  explist: (node) =>
    with @line!
      \append_list [@value v for v in *node[2:]], ", "

  parens: (node) =>
    @line "(", @value(node[2]), ")"

  string: (node) =>
    _, delim, inner, delim_end = unpack node
    delim..inner..(delim_end or delim)

  if: (node) =>
    with @block "(function()", "end)()"
      \stm node, returner

  comprehension: (node) =>
    exp = node[2]

    with @block "(function()", "end)()"
      tmp_name = \init_free_var "accum", {"table"}

      action = (value) ->
        {"chain", "table.insert", {"call", {tmp_name, value}}}

      \stm node, action
      \stm {"return", tmp_name}

  chain: (node) =>
    callee = node[2]

    if callee == -1
      callee = @get "scope_var"
      if not callee then user_error "Short-dot syntax must be called within a with block"

    sup = @get "super"
    if callee == "super" and sup
      return @value sup self, node

    chain_item = (node) ->
      t, arg = unpack node
      if t == "call"
        "(", @values(arg), ")"
      elseif t == "index"
        "[", @value(arg), "]"
      elseif t == "dot"
        ".", arg
      elseif t == "colon"
        ":", arg, chain_item(node[3])
      elseif t == "colon_stub"
        user_error "Uncalled colon stub"
      else
        error "Unknown chain action: "..t

    actions = with @line!
      \append chain_item action for action in *node[3:]

    if ntype(callee) == "self" and node[3] and ntype(node[3]) == "call"
      callee[1] = "self_colon"

    callee_value = @name callee
    callee_value = @line "(", callee_value, ")" if ntype(callee) == "exp"

    @line callee_value, actions

  fndef: (node) =>
    _, args, arrow, block = unpack node

    default_args = {}
    format_names = (arg) ->
      if type(arg) == "string"
        arg
      else
        insert default_args, arg
        arg[1]

    args = [format_names arg for arg in *args]

    if arrow == "fat"
      insert args, 1, "self"

    with @block "function("..concat(args, ", ")..")"
      \put_name name for name in *args

      for default in *default_args
        name, value = unpack default
        \stm {
          'if', {'exp', name, '==', 'nil'}, {
            {'assign', {name}, {value}}
          }
        }

      \ret_stms block

  table: (node) =>
    _, items = unpack node
    with @block "{", "}"
      .delim = ","

      format_line = (tuple) ->
        if #tuple == 2
          key, value = unpack tuple

          if type(key) == "string" and data.lua_keywords[key]
            key = {"string", '"', key}

          assign = if type(key) != "string"
            @line "[", \value(key), "]"
          else
            key

          \set "current_block", key
          out = @line assign, " = ", \value(value)
          \set "current_block", nil
          out
        else
          @line \value tuple[1]

      if items
        \add format_line line for line in *items

  minus: (node) =>
    @line "-", @value node[2]

  length: (node) =>
    @line "#", @value node[2]

  not: (node) =>
    @line "not ", @value node[2]

  self: (node) =>
    "self."..@value node[2]

  self_colon: (node) =>
    "self:"..@value node[2]
