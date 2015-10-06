
util = require "moonscript.util"
dump = require "moonscript.dump"
transform = require "moonscript.transform"

import NameProxy, LocalName from require "moonscript.transform.names"
import Set from require "moonscript.data"
import ntype, value_can_be_statement from require "moonscript.types"

statement_compilers = require "moonscript.compile.statement"
value_compilers = require "moonscript.compile.value"

import concat, insert from table
import pos_to_line, get_closest_line, trim, unpack from util

mtype = util.moon.type

indent_char = "  "

local Line, DelayedLine, Lines, Block, RootBlock

-- a buffer for building up lines
class Lines
  new: =>
    @posmap = {}

  mark_pos: (pos, line=#@) =>
    @posmap[line] = pos unless @posmap[line]

  -- append a line or lines to the buffer
  add: (item) =>
    switch mtype item
      when Line
        item\render self
      when Block
        item\render self
      else -- also captures DelayedLine
        @[#@ + 1] = item
    @

  flatten_posmap: (line_no=0, out={}) =>
    posmap = @posmap
    for i, l in ipairs @
      switch mtype l
        when "string", DelayedLine
          line_no += 1
          out[line_no] = posmap[i]

          line_no += 1 for _ in l\gmatch"\n"
          out[line_no] = posmap[i]
        when Lines
          _, line_no = l\flatten_posmap line_no, out
        else
          error "Unknown item in Lines: #{l}"

    out, line_no

  flatten: (indent=nil, buffer={}) =>
    for i = 1, #@
      l = @[i]
      t = mtype l

      if t == DelayedLine
        l = l\render!
        t = "string"

      switch t
        when "string"
          insert buffer, indent if indent
          insert buffer, l

          -- insert breaks between ambiguous statements
          if "string" == type @[i + 1]
            lc = l\sub(-1)
            if (lc == ")" or lc == "]") and @[i + 1]\sub(1,1) == "("
              insert buffer, ";"

          insert buffer, "\n"
        when Lines
           l\flatten indent and indent .. indent_char or indent_char, buffer
        else
          error "Unknown item in Lines: #{l}"
    buffer

  __tostring: =>
    -- strip non-array elements
    strip = (t) ->
      if "table" == type t
        [strip v for v in *t]
      else
        t

    "Lines<#{util.dump(strip @)\sub 1, -2}>"

-- Buffer for building up a line
-- A plain old table holding either strings or Block objects.
-- Adding a line to a line will cause that line to be merged in.
class Line
  pos: nil

  append_list: (items, delim) =>
    for i = 1,#items
      @append items[i]
      if i < #items then insert self, delim
    nil

  append: (first, ...) =>
    if Line == mtype first
      -- print "appending line to line", first.pos, first
      @pos = first.pos unless @pos -- bubble pos if there isn't one
      @append value for value in *first
    else
      insert self, first

    if ...
      @append ...

  -- todo: try to remove concats from here
  render: (buffer) =>
    current = {}

    add_current = ->
      buffer\add concat current
      buffer\mark_pos @pos

    for chunk in *@
      switch mtype chunk
        when Block
          for block_chunk in *chunk\render Lines!
            if "string" == type block_chunk
              insert current, block_chunk
            else
              add_current!
              buffer\add block_chunk
              current = {}
        else
          insert current, chunk

    if current[1]
      add_current!

    buffer

  __tostring: =>
    "Line<#{util.dump(@)\sub 1, -2}>"

class DelayedLine
  new: (fn) =>
    @prepare = fn

  prepare: ->

  render: =>
    @prepare!
    concat @

class Block
  header: "do"
  footer: "end"

  export_all: false
  export_proper: false

  value_compilers: value_compilers
  statement_compilers: statement_compilers

  __tostring: =>
    h = if "string" == type @header
      @header
    else
      unpack @header\render {}

    "Block<#{h}> <- " .. tostring @parent

  new: (@parent, @header, @footer) =>
    @_lines = Lines!

    @_names = {}
    @_state = {}
    @_listeners = {}

    with transform
      @transform = {
        value: .Value\bind self
        statement: .Statement\bind self
      }

    if @parent
      @root = @parent.root
      @indent = @parent.indent + 1
      setmetatable @_state, { __index: @parent._state }
      setmetatable @_listeners, { __index: @parent._listeners }
    else
      @indent = 0

  set: (name, value) =>
    @_state[name] = value

  get: (name) =>
    @_state[name]

  get_current: (name) =>
    rawget @_state, name

  listen: (name, fn) =>
    @_listeners[name] = fn

  unlisten: (name) =>
    @_listeners[name] = nil

  send: (name, ...) =>
    if fn = @_listeners[name]
      fn self, ...

  extract_assign_name: (node) =>
    is_local = false
    real_name = switch mtype node
      when LocalName
        is_local = true
        node\get_name self
      when NameProxy
        node\get_name self
      when "table"
        node[1] == "ref" and node[2]
      when "string"
        -- TOOD: some legacy transfomers might use string for ref
        node

    real_name, is_local

  declare: (names) =>
    undeclared = for name in *names
      real_name, is_local = @extract_assign_name name
      continue unless is_local or real_name and not @has_name real_name, true
      -- this also puts exported names so they can be assigned a new value in
      -- deeper scope
      @put_name real_name
      continue if @name_exported real_name
      real_name

    undeclared

  whitelist_names: (names) =>
    @_name_whitelist = Set names

  name_exported: (name) =>
    return true if @export_all
    return true if @export_proper and name\match"^%u"

  put_name: (name, ...) =>
    value = ...
    value = true if select("#", ...) == 0

    name = name\get_name self if NameProxy == mtype name
    @_names[name] = value

  -- Check if a name is defined in the current or any enclosing scope
  -- skip_exports: ignore names that have been exported using `export`
  has_name: (name, skip_exports) =>
    return true if not skip_exports and @name_exported name

    yes = @_names[name]
    if yes == nil and @parent
      if not @_name_whitelist or @_name_whitelist[name]
        @parent\has_name name, true
    else
      yes

  is_local: (node) =>
    t = mtype node

    return @has_name(node, false) if t == "string"
    return true if t == NameProxy or t == LocalName

    if t == "table"
      if node[1] == "ref" or (node[1] == "chain" and #node == 2)
        return @is_local node[2]

    false

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

  -- add something to the line buffer
  add: (item, pos) =>
    with @_lines
      \add item
      \mark_pos pos if pos
    item

  -- todo: pass in buffer as argument
  render: (buffer) =>
    buffer\add @header
    buffer\mark_pos @pos

    if @next
      buffer\add @_lines
      @next\render buffer
    else
      -- join an empty block into a single line
      if #@_lines == 0 and "string" == type buffer[#buffer]
        buffer[#buffer] ..= " " .. (unpack Lines!\add @footer)
      else
        buffer\add @_lines
        buffer\add @footer
        buffer\mark_pos @pos

    buffer

  block: (header, footer) =>
    Block self, header, footer

  line: (...) =>
    with Line!
      \append ...

  is_stm: (node) =>
    @statement_compilers[ntype node] != nil

  is_value: (node) =>
    t = ntype node
    @value_compilers[t] != nil or t == "value"

  -- compile name for assign
  name: (node, ...) =>
    if type(node) == "string"
      node
    else
      @value node, ...

  value: (node, ...) =>
    node = @transform.value node
    action = if type(node) != "table"
      "raw_value"
    else
      node[1]

    fn = @value_compilers[action]
    unless fn
      error {
        "compile-error"
        "Failed to find value compiler for: " .. dump.value node
        node[-1]
      }

    out = fn self, node, ...

    -- store the pos, creating a line if necessary
    if type(node) == "table" and node[-1]
      if type(out) == "string"
        out = with Line! do \append out
      out.pos = node[-1]

    out

  values: (values, delim) =>
    delim = delim or ', '
    with Line!
      \append_list [@value v for v in *values], delim

  stm: (node, ...) =>
    return if not node -- skip blank statements
    node = @transform.statement node

    result = if fn = @statement_compilers[ntype(node)]
      fn @, node, ...
    else
      if value_can_be_statement node
        @value node
      else
        -- coerce value into statement
        @stm {"assign", {"_"}, {node}}

    if result
      if type(node) == "table" and type(result) == "table" and node[-1]
        result.pos = node[-1]
      @add result

    nil

  stms: (stms, ret) =>
    error "deprecated stms call, use transformer" if ret
    {:current_stms, :current_stm_i} = @

    @current_stms = stms
    for i=1,#stms
      @current_stm_i = i
      @stm stms[i]

    @current_stms = current_stms
    @current_stm_i = current_stm_i

    nil

  -- takes the existing set of lines and replaces them with the result of
  -- calling fn on them
  splice: (fn) =>
    lines = {"lines", @_lines}
    @_lines = Lines!
    @stms fn lines

class RootBlock extends Block
  new: (@options) =>
    @root = self
    super!

  __tostring: => "RootBlock<>"

  root_stms: (stms) =>
    unless @options.implicitly_return_root == false
      stms = transform.Statement.transformers.root_stms self, stms
    @stms stms

  render: =>
    -- print @_lines
    buffer = @_lines\flatten!
    buffer[#buffer] = nil if buffer[#buffer] == "\n"
    table.concat buffer

format_error = (msg, pos, file_str) ->
  line_message = if pos
    line = pos_to_line file_str, pos
    line_str, line = get_closest_line file_str, line
    line_str = line_str or ""
    (" [%d] >>    %s")\format line, trim line_str

  concat {
    "Compile error: "..msg
    line_message
  }, "\n"

value = (value) ->
  out = nil
  with RootBlock!
    \add \value value
    out = \render!
  out

tree = (tree, options={}) ->
  assert tree, "missing tree"

  scope = (options.scope or RootBlock) options

  runner = coroutine.create ->
    scope\root_stms tree

  success, err = coroutine.resume runner

  unless success
    error_msg, error_pos = if type(err) == "table"
      switch err[1]
        when "user-error", "compile-error"
          unpack err, 2
        else
          -- unknown error, bubble it
          error "Unknown error thrown", util.dump error_msg
    else
      concat {err, debug.traceback runner}, "\n"

    return nil, error_msg, error_pos or scope.last_pos

  lua_code = scope\render!
  posmap = scope._lines\flatten_posmap!
  lua_code, posmap

-- mmmm
with data = require "moonscript.data"
  for name, cls in pairs {:Line, :Lines, :DelayedLine}
    data[name] = cls

{ :tree, :value, :format_error, :Block, :RootBlock }
