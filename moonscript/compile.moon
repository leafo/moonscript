module "moonscript.compile", package.seeall

util = require "moonscript.util"
data = require "moonscript.data"
dump = require "moonscript.dump"

require "moonscript.compile.format"
require "moonscript.compile.line"
require "moonscript.compile.value"

import ntype from data
import concat, insert from table
import pos_to_line, get_closest_line, trim from util

export tree, format_error
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
  header: "do"
  footer: "end"

  new: (@parent, @header, @footer) =>
    @current_line = 1

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

  shadow_name: (name) =>
    @_names[name] = false

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
    if node[-1]
      @last_pos = node[-1]
      if not @_posmap[@current_line]
        @_posmap[@current_line] = @last_pos

  -- add raw text as new line
  add_line_text: (text) =>
    insert @_lines, text

  append_line_table: (sub_table, offset) =>
    offset = offset + @current_line

    for line, source in pairs sub_table
      line += offset
      if not @_posmap[line]
        @_posmap[line] = source

  add_line_tables: (line) =>
      for chunk in *line
        if util.moon.type(chunk) == Block
          current = chunk
          while current
            if util.moon.type(current.header) == Line
              @add_line_tables current.header

            @append_line_table current\line_table!, 0
            @current_line += current.current_line
            current = current.next

  -- add a line object
  add: (line) =>
    t = util.moon.type line

    if t == "string"
      @add_line_text line
    elseif t == Block
      @add @line line
    elseif t == Line
      @add_line_tables line
      @add_line_text line\render!
      @current_line += 1
    else
      error "Adding unknown item"

  push: =>
    @_names = setmetatable {}, { __index: @_names }

  pop: =>
    @_names = getmetatable(@_names).__index

  _insert_breaks: =>
    for i = 1, #@_lines - 1
      left, right = @_lines[i], @_lines[i+1]
      if left\sub(-1) == ")" and right\sub(1,1) == "("
        @_lines[i] = @_lines[i]..";"

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

    indent = indent_char\rep @indent

    -- inject semicolons for ambiguous lines
    if not @delim then @_insert_breaks!

    body = indent .. concat @_lines, (@delim or "") .. "\n" .. indent

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
    with Line!
      \append_list [@value v for v in *values], delim

  stm: (node, ...) =>
    fn = line_compile[ntype(node)]
    if not fn
      -- coerce value into statement
      if has_value node
        @stm {"assign", {"_"}, {node}}
      else
        @add @value node
    else
      @mark_pos node
      out = fn self, node, ...
      @add out if out

  ret_stms: (stms, ret) =>
    if not ret
      ret = default_return

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
  render: =>
    @_insert_breaks!
    concat @_lines, "\n"

Block = Block_

format_error = (msg, pos, file_str) ->
  line = pos_to_line file_str, pos
  line_str, line = get_closest_line file_str, line
  line_str = line_str or ""
  concat {
    "Compile error: "..msg
    (" [%d] >>    %s")\format line, trim line_str
  }, "\n"

tree = (tree) ->
  scope = RootBlock!

  runner = coroutine.create ->
    scope\stm line for line in *tree
    scope\render!

  success, result = coroutine.resume runner
  if not success
    error_msg = if type(result) == "table"
      error_type = result[1]
      if error_type == "user-error"
        result[2]
      else
        error "Unknown error thrown", util.dump error_msg
    else
      concat {result, debug.traceback runner}, "\n"

    nil, error_msg, scope.last_pos
  else
    tbl = scope\line_table!
    result, tbl

