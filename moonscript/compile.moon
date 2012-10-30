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
import pos_to_line, get_line, get_closest_line, trim from util

mtype = util.moon.type

export tree, value, format_error
export Block, RootBlock

local Line, Lines

-- a buffer for building up lines
class Lines
  new: =>
    @posmap = {}

  -- append a line or lines to the buffer
  add: (item) =>
    switch mtype item
      when Line
        item\render self
      when Block
        item\render self
      else
        @[#@ + 1] = item
    @

  __tostring: =>
    -- strip non-array elements
    strip = (t) ->
      if "table" == type t
        [strip v for v in *t]
      else
        t

    -- copy with only array elements
    "Lines<#{util.dump(strip @)\sub 1, -2}>"
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

  -- todo: try to remove concats from here
  render: (buffer) =>
    current = {}

    add_current = ->
      buffer\add concat current

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

    if #current > 0
      add_current!

    buffer

  __tostring: =>
    "Line<#{util.dump(@)\sub 1, -2}>"

class Block
  header: "do"
  footer: "end"

  export_all: false
  export_proper: false

  __tostring: =>
    h = if "string" == type @header
      @header
    else
      unpack @header\render {}

    "Block<#{h}> <- " .. tostring @parent

  new: (@parent, @header, @footer) =>
    @_lines = Lines!

    @_posmap = {} -- todo: kill me
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

  -- maps from a output (lua) line number to a character position in the
  -- original moon file
  line_table: =>
    @_posmap

  set: (name, value) =>
    @_state[name] = value

  get: (name) =>
    @_state[name]

  listen: (name, fn) =>
    @_listeners[name] = fn

  unlisten: (name) =>
    @_listeners[name] = nil

  send: (name, ...) =>
    if fn = @_listeners[name]
      fn self, ...

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

  put_name: (name, ...) =>
    value = ...
    value = true if select("#", ...) == 0

    name = name\get_name self if util.moon.type(name) == NameProxy
    @_names[name] = value

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

  mark_pos: (line_no, node) =>
    if pos = node[-1]
      @last_pos = pos
      @_posmap[line_no] = pos unless @_posmap[line_no]

  append_posmap: (map) =>
    print "appending pos", self
    @_posmap[#@_posmap + 1] = map

  -- append_line_table: (sub_table, offset) =>
  --   offset = offset + @current_line

  --   for line, source in pairs sub_table
  --     line += offset
  --     if not @_posmap[line]
  --       @_posmap[line] = source

  -- add_line_tables: (line) =>
  --     for chunk in *line
  --       if util.moon.type(chunk) == Block
  --         current = chunk
  --         while current
  --           if util.moon.type(current.header) == Line
  --             @add_line_tables current.header

  --           @append_line_table current\line_table!, 0
  --           @current_line += current.current_line
  --           current = current.next

  -- add a line object
  add: (item) =>
    @_lines\add item
    item

  -- todo: pass in buffer as argument
  render: (buffer) =>
    buffer\add @header

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

    buffer

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
    node = @transform.value node
    action = if type(node) != "table"
      "raw_value"
    else
      node[1]

    fn = value_compile[action]
    error "Failed to compile value: "..dump.value node if not fn
    fn self, node, ...

  values: (values, delim) =>
    delim = delim or ', '
    with Line!
      \append_list [@value v for v in *values], delim


  block_iterator = (list) ->
    coroutine.wrap ->
      for item in *list
        if Block == mtype item
          coroutine.yield item

  stm: (node, ...) =>
    return if not node -- skip blank statements
    node = @transform.statement node

    before = #@_lines

    added = if fn = line_compile[ntype(node)]
      out = fn self, node, ...
      @add out if out
    else
      -- coerce value into statement
      if has_value node
        @stm {"assign", {"_"}, {node}}
      else
        @add @value node

    -- mark pos for each line added
    if added
      print "added #{#@_lines - before} lines"

      list = if Line == mtype added then added else {added}
      next_block = block_iterator list

      for l=before + 1,#@_lines
        if "table" == type @_lines[l]
          block = next_block!
          block._posmap.num_lines = #block._lines
          @_posmap[l] = block._posmap
        else
          @mark_pos l, node
    nil

  stms: (stms, ret) =>
    error "deprecated stms call, use transformer" if ret
    @stm stm for stm in *stms
    nil

  splice: (fn) =>
    lines = {"lines", @_lines}
    @_lines = Lines!
    @stms fn lines

-- move this into Lines
flatten_lines = (lines, indent=nil, buffer={}) ->
  for i = 1, #lines
    l = lines[i]
    switch type l
      when "string"
        insert buffer, indent if indent
        insert buffer, l

        -- insert breaks between ambiguous statements
        if "string" == type lines[i + 1]
          lc = l\sub(-1)
          if (lc == ")" or lc == "]") and lines[i + 1]\sub(1,1) == "("
            insert buffer, ";"

        insert buffer, "\n"
        last = l
      when "table"
        flatten_lines l, indent and indent .. indent_char or indent_char, buffer

  buffer

flatten_posmap = (posmap, dl=0, out={}) ->
  for k,v in pairs posmap
    continue if "string" == type k
    if "table" == type v
      flatten_posmap v, k - 1 + dl, out
      dl += v.num_lines - 1
    else
      out[k + dl] = v

  out

debug_posmap = (posmap, fname=error"pass in input file", lua_code) ->
  moon_code = io.open(fname)\read "*a"

  tuples = [{k, v} for k, v in pairs posmap]

  table.sort tuples, (a, b) -> a[1] < b[1]

  lines = for pair in *tuples
    lua_line, pos = unpack pair
    moon_line = pos_to_line moon_code, pos

    lua_text = get_line lua_code, lua_line
    moon_text = get_closest_line moon_code, moon_line

    "#{pos}\t #{lua_line}:[ #{trim lua_text} ] >> #{moon_line}:[ #{trim moon_text} ]"

  concat(lines, "\n") .. "\n"

class RootBlock extends Block
  new: (...) =>
    @root = self
    super ...

  __tostring: => "RootBlock<>"

  render: =>
    -- print util.dump @_lines
    buffer = flatten_lines @_lines
    buffer[#buffer] = nil if buffer[#buffer] == "\n"
    table.concat buffer

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
    raw_posmap = scope\line_table!
    posmap = flatten_posmap raw_posmap
    print util.dump raw_posmap
    print util.dump posmap
    print debug_posmap posmap, "scrap.moon", result
    result, posmap

