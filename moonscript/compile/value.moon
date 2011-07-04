
module "moonscript.compile", package.seeall

util = require "moonscript.util"
data = require "moonscript.data"

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

    -- ugly
    concat [_comp i,v for i,v in ipairs node when i > 1], " "

  update: (node) =>
    _, name = unpack node
    @stm node
    @name name

  explist: (node) =>
    concat [@value v for v in *node[2:]], ", "

  parens: (node) =>
    "("..(@value node[2])..")"

  string: (node) =>
    _, delim, inner, delim_end = unpack node
    delim..inner..(delim_end or delim)

  if: (node) =>
    func = @block!
    func\stm node, returner
    @format "(function()", func\render!, "end)()"

  comprehension: (node) =>
    exp = node[2]
    func = @block!
    tmp_name = func\free_name!

    func\add_line "local", tmp_name, "= {}"

    action = func\block!
    action\add_line ("table.insert(%s, %s)")\format(tmp_name, func\value exp)
    func\stm node, action

    func\add_line "return", tmp_name

    @format "(function()", func\render!, "end)()"

  chain: (node) =>
    callee = node[2]

    if callee == -1
      callee = @get"scope_var"
      if not callee then error"Short-dot syntax must be called within a with block"

    sup = @get "super"
    if callee == "super" and sup
      return @value sup self, node

    chain_item = (node) ->
      t, arg = unpack node
      if t == "call"
        "("..(@values arg)..")"
      elseif t == "index"
        "["..(@value arg).."]"
      elseif t == "dot"
        "."..arg
      elseif t == "colon"
        ":"..arg..(chain_item node[3])
      else
        error "Unknown chain action: "..t

    actions = [chain_item act for act in *node[3:]]

    if ntype(callee) == "self" and node[3] and ntype(node[3]) == "call"
      callee[1] = "self_colon"

    callee_value = @name callee
    callee_value = "("..callee_value..")" if ntype(callee) == "exp"

    return @name(callee)..concat(actions)

  fndef: (node) =>
    _, args, arrow, block = unpack node

    if arrow == "fat"
      insert args, 1, "self"

    b = @block!
    b\put_name name for name in *args
    b\ret_stms block

    decl = "function("..(concat args, ", ")..")"
    if #b._lines == 0
      decl.." end"
    elseif #b._lines == 1
      concat {decl, b._lines[1], "end"}, " "
    else
      @format decl, b._lines, "end"

  table: (node) =>
    _, items = unpack node

    inner = @block! -- handle indent
    _comp = (i, tuple) ->
      out = if #tuple == 2
        key, value = unpack tuple

        if type(key) == "string" and data.lua_keywords[key]
          key = {"string", '"', key}

        key_val = @value key
        key = if type(key) != "string"
          ("[%s]")\format key_val
        else
          key_val

        inner\set "current_block", key_val
        value = inner\value value
        inner\set "current_block", nil

        ("%s = %s")\format key, value
      else
        inner\value tuple[1]

      out.."," if i != #items else out

    values = [_comp i,v for i,v in ipairs items]

    if #values > 3
      @format "{", values, "}"
    else
      "{ "..(concat values, " ").." }"

  minus: (node) =>
    "-"..@value node[2]

  length: (node) =>
    "#"..@value node[2]

  not: (node) =>
    "not "..@value node[2]

  self: (node) =>
    "self."..@value node[2]

  self_colon: (node) =>
    "self:"..@value node[2]
