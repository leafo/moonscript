module "moonscript.compile", package.seeall

util = require "moonscript.util"
data = require "moonscript.data"
dump = require "moonscript.dump"

require "moonscript.compile.format"
require "moonscript.compile.line"
require "moonscript.compile.value"

import ntype from data
import concat, insert from table

export tree
export Block

-- buffer for building up a line
class Line
  _append_single: (item) =>
    if util.moon.type(item) == Line
      @_append_single value for value in *item
    else
      insert self, item
    nil

  append_list: (items, delim) =>
    for i = 1,#items
      @_append_single items[i]
      if i < #items then insert self, delim

  append: (...) =>
    @_append_single item for item in *{...}
    nil

  render: =>
    buff = {}
    for i = 1,#self
      c = self[i]
      insert buff, if util.moon.type(c) == Block
        c\render!
      else
        c
    concat buff

class Block_
  new: (@parent, @header, @footer) =>
    @header = "do" if not @header
    @footer = "end" if not @footer

    @line_offset = 1

    @_lines = {}
    @_posmap = {}
    @_names = {}
    @_state = {}

    if @parent
      @indent = @parent.indent + 1
      setmetatable @_state, { __index: @parent._state }
      setmetatable @_names, { __index: @parent._names }
    else
      @indent = 0

  line_table: =>
    @_posmap

  set: (name, value) =>
    @_state[name] = value

  get: (name) =>
    @_state[name]

  declare: (names) =>
    undeclared = [name for name in *names when type(name) == "string" and not @has_name name]
    @put_name name for name in *undeclared
    undeclared

  put_name: (name) =>
    @_names[name] = true

  has_name: (name) =>
    @_names[name]

  free_name: (prefix, dont_put) =>
    prefix = prefix or "moon"
    searching = true
    name, i = nil, 0
    while searching
      name = concat {"", prefix, i}, "_"
      i = i + 1
      searching = @has_name name

    @put_name name if not dont_put
    name

  init_free_var: (prefix, value) =>
    name = @free_name prefix, true
    @stm {"assign", {name}, {value}}
    name

  mark_pos: (node) =>
    @_posmap[#@_lines + 1] = node[-1]

  -- add raw text as new line
  add_line_text: (text) =>
    @line_offset += 1
    insert @_lines, text

  -- add a line object
  add: (line) =>
    t = util.moon.type line

    if t == "string"
      @add_line_text line
    elseif t == Block
      @add @line line
    elseif t == Line
      @add_line_text line\render!
    else
      error "Adding unknown item"

  push: =>
    @_names = setmetatable {}, { __index: @_names }

  pop: =>
    @_names = getmetatable(@_names).__index

  render: =>
    flatten = (line) ->
      if type(line) == "string"
        line
      else
        line\render!

    header = flatten @header

    if #@_lines == 0
      footer = flatten @footer
      return concat {header, footer}, " "

    body = pretty @_lines, indent_char\rep @indent

    concat {
      header,
      body,
      indent_char\rep(@indent - 1) .. if @next then @next\render! else flatten @footer
    }, "\n"

  block: (header, footer) =>
    Block self, header, footer

  line: (...) =>
    with Line!
      \append ...

  is_stm: (node) =>
    line_compile[ntype node] != nil

  is_value: (node) =>
    t = ntype node
    value_compile[t] != nil or t == "value"

  -- line wise compile functions
  name: (node) => @value node
  value: (node, ...) =>
    return tostring node if type(node) != "table"
    fn = value_compile[node[1]]
    error "Failed to compile value: "..dump.value node if not fn
    @mark_pos node
    fn self, node, ...

  values: (values, delim) =>
    delim = delim or ', '
    concat [@value v for v in *values], delim

  stm: (node, ...) =>
    fn = line_compile[ntype(node)]
    if not fn
      -- coerce value into statement
      if has_value node
        @stm {"assign", {"_"}, {node}}
      else
        @add @value node
    else
      out = fn self, node, ...
      @add out if out

  ret_stms: (stms, ret) =>
    if not ret
      ret = returner

    -- wow I really need a for loop
    i = 1
    while i < #stms
      @stm stms[i]
      i = i + 1

    last_exp = stms[i]

    if last_exp
      if cascading[ntype(last_exp)]
        @stm last_exp, ret
      elseif @is_value last_exp
        line = ret stms[i]
        if @is_stm line
          @stm line
        else
          error "got a value from implicit return"
      else
        -- nothing we can do with a statement except show it
        @stm last_exp

    nil

  stms: (stms, ret) =>
    if ret
      @ret_stms stms, ret
    else
      @stm stm for stm in *stms
    nil

class RootBlock extends Block_
  render: => concat @_lines, "\n"

Block = Block_

tree = (tree) ->
  scope = RootBlock!
  scope\stm line for line in *tree

  scope\render!, scope\line_table!

