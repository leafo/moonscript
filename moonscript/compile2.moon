module "moonscript.compile", package.seeall

util = require "moonscript.util"
data = require "moonscript.data"
dump = require "moonscript.dump"

require "moonscript.compile.format"
require "moonscript.compile.line"

import map, bind, itwos, every, reversed from util
import Stack, Set, ntype from data
import concat, insert from table

export tree

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

build_compiler = ->
  Block(nil)
  setmetatable {}, { __index: compiler_index }

tree = (tree) ->
  scope = Block!
  scope\stm line for line in *tree

  -- print util.dump scope._posmap

  scope\render!, scope\line_table!

