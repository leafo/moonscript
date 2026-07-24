
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

-- lua binary operator precedence, from loosest to tightest binding
binary_op_prec = do
  out = {}
  for prec, ops in ipairs {
    {"or"}
    {"and"}
    {"<", ">", "<=", ">=", "~=", "!=", "=="}
    {"|"}
    {"&"}
    {"<<", ">>"}
    {".."}
    {"+", "-"}
    {"*", "/", "//", "%"}
    {"^"}
  }
    out[op] = prec for op in *ops
  out

right_assoc_op = {
  "..": true
  "^": true
}

-- the loosest binding operator in a flat exp node, nil if there are none
exp_precedence = (node) ->
  local min_prec
  for i=3, #node, 2
    if prec = binary_op_prec[node[i]]
      min_prec = prec if not min_prec or prec < min_prec
  min_prec

{
  scoped: (node) =>
    {_, before, value, after} = node
    before and before\call @
    with @value value
      after and after\call @

  -- list of values separated by binary operators
  exp: (node) =>
    -- exp nodes nested by transformations (eg. string interpolation) must
    -- keep their grouping if an adjacent operator binds tighter than one of
    -- their own operators
    needs_parens = (value, i) ->
      return false unless type(value) == "table" and value[1] == "exp"
      inner = exp_precedence value
      return false unless inner

      if i > 2
        if left = binary_op_prec[node[i - 1]]
          return true if left > inner
          return true if left == inner and not right_assoc_op[node[i - 1]]

      if i < #node
        if right = binary_op_prec[node[i + 1]]
          return true if right > inner
          -- equal precedence on the right regroups under a right associative
          -- operator: an exp holding a .. b rendered flat as a .. b .. c
          -- evaluates as a .. (b .. c), observable through __concat
          return true if right == inner and right_assoc_op[node[i + 1]]

      false

    _comp = (i, value) ->
      if i % 2 == 1 and value == "!="
        value = "~="

      -- transform now so nested exps (eg. from string interpolation) are
      -- visible to the parenthesization check
      if type(value) == "table"
        value = @transform.value value

      if needs_parens value, i
        @line "(", @value(value), ")"
      else
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
        user_error "Short-dot syntax must be called within a with block", node[-1]
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
      else
        error "Unknown chain action: #{t}"

    if (callee_type == "self" or callee_type == "self_class") and node[3] and ntype(node[3]) == "call"
      callee[1] = callee_type.."_colon"

    callee_value = @value callee

    -- expressions and table literals can't be subscripted directly in lua
    switch ntype callee
      when "exp", "table"
        callee_value = @line "(", callee_value, ")"

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
      .header = "function("..concat(arg_names, ", ")..")"

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
    field_name = @name node[2]
    if data.lua_keywords[field_name]
      @value {"chain", "self", {"index", {
        "string", '"', field_name
      }}}
    else
      "self.#{field_name}"

  self_class: (node) =>
    field_name = @name node[2]

    if data.lua_keywords[field_name]
      @value {"chain", "self", {"dot", "__class"}, {"index", {
        "string", '"', field_name
      }}}
    else
      "self.__class.#{field_name}"

  self_colon: (node) =>
    "self:#{@name node[2]}"

  self_class_colon: (node) =>
    "self.__class:#{@name node[2]}"

  -- a variable reference
  ref: (value) =>
    if sup = value[2] == "super" and @get "super"
      return @value sup @

    tostring value[2]

  -- catch all pure string values
  raw_value: (value) =>
    tostring value
}
