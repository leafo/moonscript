module "moonscript.compile", package.seeall

util = require "moonscript.util"
dump = require "moonscript.dump"

require "moonscript.compile.format"
require "moonscript.compile.statement"
require "moonscript.compile.value"

transform = require "moonscript.transform"

import NameProxy, LocalName from transform
import Set from require "moonscript.data"
import ntype from require "moonscript.types"

import concat, insert from table
import pos_to_line, get_closest_line, trim from util

export tree, value, format_error
export Block, RootBlock

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
        c\bubble!
        c\render!
      else
        c
    concat buff

class Block
  header: "do"
  footer: "end"

  export_all: false
  export_proper: false

  __tostring: => "Block<> <- " .. tostring @parent

  new: (@parent, @header, @footer) =>
    @current_line = 1

    @_lines = {}
    @_posmap = {}
    @_names = {}
    @_state = {}

    if @parent
      @root = @parent.root
      @indent = @parent.indent + 1
      setmetatable @_state, { __index: @parent._state }
    else
      @indent = 0

  -- bubble properties into parent
  bubble: (other=@parent) =>
    has_varargs = @has_varargs and not @has_name "..."
    other.has_varargs = other.has_varargs or has_varargs

  line_table: =>
    @_posmap

  set: (name, value) =>
    @_state[name] = value

  get: (name) =>
    @_state[name]

  declare: (names) =>
    undeclared = for name in *names
      is_local = false
      real_name = switch util.moon.type name
        when LocalName
          is_local = true
          name\get_name self
        when NameProxy then name\get_name self
        when "string" then name

      real_name if is_local or real_name and not @has_name real_name

    @put_name name for name in *undeclared
    undeclared

  whitelist_names: (names) =>
    @_name_whitelist = Set names

  put_name: (name) =>
    name = name\get_name self if util.moon.type(name) == NameProxy
    @_names[name] = true

  has_name: (name, skip_exports) =>
    if not skip_exports
      return true if @export_all
      return true if @export_proper and name\match"^[A-Z]"

    yes = @_names[name]
    if yes == nil and @parent
      if not @_name_whitelist or @_name_whitelist[name]
        @parent\has_name name, true
    else
      yes

  free_name: (prefix, dont_put) =>
    prefix = prefix or "moon"
    searching = true
    name, i = nil, 0
    while searching
      name = concat {"", prefix, i}, "_"
      i = i + 1
      searching = @has_name name, true

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
    nil

  _insert_breaks: =>
    for i = 1, #@_lines - 1
      left, right = @_lines[i], @_lines[i+1]
      lc = left\sub(-1)
      if (lc == ")" or lc == "]") and right\sub(1,1) == "("
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
    node = @root.transform.value node
    action = if type(node) != "table"
      "raw_value"
    else
      @mark_pos node
      node[1]

    fn = value_compile[action]
    error "Failed to compile value: "..dump.value node if not fn
    fn self, node, ...

  values: (values, delim) =>
    delim = delim or ', '
    with Line!
      \append_list [@value v for v in *values], delim

  stm: (node, ...) =>
    return if not node -- slip blank statements
    node = @root.transform.statement node
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
    nil

  stms: (stms, ret) =>
    error "deprecated stms call, use transformer" if ret
    @stm stm for stm in *stms
    nil

class RootBlock extends Block
  new: (...) =>
    @root = self
    @transform = {
      value: transform.Value\instance self
      statement: transform.Statement\instance self
    }
    super ...

  __tostring: => "RootBlock<>"

  render: =>
    @_insert_breaks!
    concat @_lines, "\n"

format_error = (msg, pos, file_str) ->
  line = pos_to_line file_str, pos
  line_str, line = get_closest_line file_str, line
  line_str = line_str or ""
  concat {
    "Compile error: "..msg
    (" [%d] >>    %s")\format line, trim line_str
  }, "\n"

value = (value) ->
  out = nil
  with RootBlock!
    \add \value value
    out = \render!
  out

tree = (tree, scope=RootBlock!) ->
  assert tree, "missing tree"

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

