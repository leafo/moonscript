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

class Block
  new: (@parent) =>
    @set_indent @parent and @parent.indent + 1 or 0
    @_lines = {}
    @_posmap = {}
    @_names = {}
    @_state = {}

    if @parent
      setmetatable @_state, { __index: @parent._state }
      setmetatable @_names, { __index: @parent._names }

  line_table: =>
    @_posmap

  set: (name, value) =>
    @_state[name] = value

  get: (name) =>
    @_state[name]

  set_indent: (depth) =>
    @indent = depth
    @lead = indent_char\rep @indent

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

  mark_pos: (node) =>
    @_posmap[#@_lines + 1] = node[-1]

  add_lines: (lines) =>
    insert @_lines, line for line in *lines
    nil

  add_line: (...) =>
    args = {...}
    line = if #args == 1 then args[1] else concat args, " "

    insert @_lines, line

  push: =>
    @_names = setmetatable {}, { __index: @_names }

  pop: =>
    @_names = getmetatable(@_names).__index

  format: (...) =>
    pretty {...}, @lead

  render: =>
    out = pretty @_lines, @lead
    if @indent > 0
      out = indent_char..out
    out

  block: (node) =>
    Block(self)

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
        @add_line @value node
    else
      out = fn self, node, ...
      @add_line out if out

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

tree = (tree) ->
  scope = Block!
  scope\stm line for line in *tree

  scope\render!, scope\line_table!

