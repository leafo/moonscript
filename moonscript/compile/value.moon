
util = require "moonscript.util"
data = require "moonscript.data"

import ntype from require "moonscript.types"
import user_error from require "moonscript.errors"
import concat, insert from table
import unpack from util

table_delim = ","

string_chars = {
  "\r": "\\r"
  "\n": "\\n"
}

{
  scoped: (node) =>
    {_, before, value, after} = node
    before and before\call @
    with @value value
      after and after\call @

  -- list of values separated by binary operators
  exp: (node) =>
    _comp = (i, value) ->
      if i % 2 == 1 and value == "!="
        value = "~="
      @value value

    with @line!
      \append_list [_comp i,v for i,v in ipairs node when i > 1], " "

  -- list of expressions separated by commas
  explist: (node) =>
    with @line!
      \append_list [@value v for v in *node[2,]], ", "

  parens: (node) =>
    @line "(", @value(node[2]), ")"

  string: (node) =>
    delim, inner = unpack node, 2
    end_delim = delim\gsub "%[", "]"
    if delim == "'" or delim == '"'
      inner = inner\gsub "[\r\n]", string_chars

    delim..inner..end_delim

  chain: (node) =>
    callee = node[2]
    callee_type = ntype callee
    item_offset = 3

    if callee_type == "dot" or callee_type == "colon" or callee_type == "index"
      callee = @get "scope_var"
      unless callee
        user_error "Short-dot syntax must be called within a with block"
      item_offset = 2

    -- TODO: don't use string literals as ref
    if callee_type == "ref" and callee[2] == "super" or callee == "super"
      if sup = @get "super"
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
        ":", tostring arg
      elseif t == "colon_stub"
        user_error "Uncalled colon stub"
      else
        error "Unknown chain action: #{t}"

    if (callee_type == "self" or callee_type == "self_class") and node[3] and ntype(node[3]) == "call"
      callee[1] = callee_type.."_colon"

    callee_value = @value callee
    callee_value = @line "(", callee_value, ")" if ntype(callee) == "exp"

    actions = with @line!
      \append chain_item action for action in *node[item_offset,]

    @line callee_value, actions

  fndef: (node) =>
    args, whitelist, arrow, block = unpack node, 2

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
          'if', {'exp', {"ref", name}, '==', 'nil'}, {
            {'assign', {name}, {value}}
          }
        }

      self_arg_values = [arg[2] for arg in *self_args]
      \stm {"assign", self_args, self_arg_values} if #self_args > 0

      \stms block

      -- inject more args if the block manipulated arguments
      -- only varargs bubbling does this currently
      if #args > #arg_names -- will only work for simple adjustments
        arg_names = [arg[1] for arg in *args]

      .header = "function("..concat(arg_names, ", ")..")"

  table: (node) =>
    items = unpack node, 2
    with @block "{", "}"
      format_line = (tuple) ->
        if #tuple == 2
          key, value = unpack tuple

          -- escape keys that are lua keywords
          if ntype(key) == "key_literal" and data.lua_keywords[key[2]]
            key = {"string", '"', key[2]}

          assign = if ntype(key) == "key_literal"
            key[2]
          else
            @line "[", \value(key), "]"

          out = @line assign, " = ", \value(value)
          out
        else
          @line \value tuple[1]

      if items
        count = #items
        for i, tuple in ipairs items
          line = format_line tuple
          line\append table_delim unless count == i
          \add line

  minus: (node) =>
    @line "-", @value node[2]

  temp_name: (node, ...) =>
    node\get_name self, ...

  number: (node) =>
    node[2]

  bitnot: (node) =>
    @line "~", @value node[2]

  length: (node) =>
    @line "#", @value node[2]

  not: (node) =>
    @line "not ", @value node[2]

  self: (node) =>
    "self."..@name node[2]

  self_class: (node) =>
    "self.__class."..@name node[2]

  self_colon: (node) =>
    "self:"..@name node[2]

  self_class_colon: (node) =>
    "self.__class:"..@name node[2]

  -- a variable reference
  ref: (value) =>
    if sup = value[2] == "super" and @get "super"
      return @value sup @

    tostring value[2]

  -- catch all pure string values
  raw_value: (value) =>
    if value == "..."
      @send "varargs"

    tostring value
}
