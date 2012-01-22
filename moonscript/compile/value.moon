
module "moonscript.compile", package.seeall

util = require "moonscript.util"
data = require "moonscript.data"

require "moonscript.compile.format"

import ntype from require "moonscript.types"
import concat, insert from table

export value_compile

table_append = (name, len, value) ->
  {
    {"update", len, "+=", 1}
    {"assign", {
      {"chain", name, {"index", len}} }, { value }}
  }

value_compile =
  -- list of values separated by binary operators
  exp: (node) =>
    _comp = (i, value) ->
      if i % 2 == 1 and value == "!="
        value = "~="
      @value value

    with @line!
      \append_list [_comp i,v for i,v in ipairs node when i > 1], " "

  -- TODO refactor
  update: (node) =>
    _, name = unpack node
    @stm node
    @name name

  -- list of expressions separated by commas
  explist: (node) =>
    with @line!
      \append_list [@value v for v in *node[2,]], ", "

  parens: (node) =>
    @line "(", @value(node[2]), ")"

  string: (node) =>
    _, delim, inner, delim_end = unpack node
    delim..inner..(delim_end or delim)

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
        -- print arg, util.dump arg
        "(", @values(arg), ")"
      elseif t == "index"
        "[", @value(arg), "]"
      elseif t == "dot"
        ".", tostring arg
      elseif t == "colon"
        ":", arg, chain_item(node[3])
      elseif t == "colon_stub"
        user_error "Uncalled colon stub"
      else
        error "Unknown chain action: "..t

    t = ntype(callee)
    if (t == "self" or t == "self_class") and node[3] and ntype(node[3]) == "call"
      callee[1] = t.."_colon"

    callee_value = @value callee
    callee_value = @line "(", callee_value, ")" if ntype(callee) == "exp"

    actions = with @line!
      \append chain_item action for action in *node[3,]

    @line callee_value, actions

  fndef: (node) =>
    _, args, whitelist, arrow, block = unpack node

    default_args = {}
    self_args = {}
    arg_names = for arg in *args
      name, default_value = unpack arg
      name = if type(name) == "string"
        name
      else
        if name[1] == "self" or name[1] == "self_class"
          insert self_args, name
        name[2]
      insert default_args, arg if default_value
      name

    if arrow == "fat"
      insert arg_names, 1, "self"

    with @block!
      if #whitelist > 0
        \whitelist_names whitelist

      \put_name name for name in *arg_names

      for default in *default_args
        name, value = unpack default
        name = name[2] if type(name) == "table"
        \stm {
          'if', {'exp', name, '==', 'nil'}, {
            {'assign', {name}, {value}}
          }
        }

      self_arg_values = [arg[2] for arg in *self_args]
      \stm {"assign", self_args, self_arg_values} if #self_args > 0

      \stms block

      -- inject more args if the block manipulated arguments
      if #args > #arg_names -- will only work for simple adjustments
        arg_names = for arg in *args
          arg[1]

      .header = "function("..concat(arg_names, ", ")..")"

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

  temp_name: (node) =>
    node\get_name self

  number: (node) =>
    node[2]

  length: (node) =>
    @line "#", @value node[2]

  not: (node) =>
    @line "not ", @value node[2]

  self: (node) =>
    "self."..@value node[2]

  self_class: (node) =>
    "self.__class."..@value node[2]

  self_colon: (node) =>
    "self:"..@value node[2]

  self_class_colon: (node) =>
    "self.__class:"..@value node[2]

  -- catch all pure string values
  raw_value: (value) =>
    sup = @get"super"
    if value == "super" and sup
      return @value sup self

    if value == "..."
      @has_varargs = true

    tostring value
