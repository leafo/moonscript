
module "moonscript.compile", package.seeall

util = require "moonscript.util"
data = require "moonscript.data"
dump = require "moonscript.dump"

import map, bind, itwos, every, reversed from util
import Stack, Set, ntype from data
import concat, insert from table

indent_char = "  "
pretty = (lines, indent) ->
  indent = indent or ""
  render = (line) ->
    if type(line) == "table"
      indent_char..pretty(line, indent..indent_char)
    else
      line

  lines = [render line for line in *lines]

  -- add semicolons for ambiguities
  fix = (i, left, k, right) ->
    if left:sub(-1) == ")" and right:sub(1,1) == "("
      lines[i] = lines[i]..";"
  fix(i,l, k,r) for i,l,k,r in itwos lines

  concat lines, "\n"..indent

returner = (exp) ->
  if ntype(exp) == "chain" and exp[2] == "return"
    -- extract the return
    items = {"explist"}
    insert items, v for v in *exp[3][2]
    {"return", items}
  else
    {"return", exp}

moonlib =
  bind: (tbl, name) ->
    concat {"moon.bind(", tbl, ".", name, ", ", tbl, ")"}

cascading = Set{ "if" }

-- does this always return a value
has_value = (node) ->
  if ntype(node) == "chain"
    ctype = ntype(node[#node])
    ctype != "call" and ctype != "colon"
  else
    true

line_compile =
  assign: (node) =>
    _, names, values = unpack node

    undeclared = [name for name in *names when type(name) == "string" and not @has_name name]

    @put_name name for name in *undeclared

    declare = "local "..(concat undeclared, ", ")

    if @is_stm values
      @add_line declare if #undeclared > 0
      if cascading[ntype(values)]
        decorate = (value) ->
          {"assign", names, {value}}

        @stm values, decorate
      else
        @add_line concat([@value n for n in *names], ", ").." = "..@value values
    else
      has_fndef = false
      i = 1
      while i <= #values
        if ntype(values[i]) == "fndef"
          has_fndef = true
        i = i +1

      -- need new compiler
      -- (if ntype(v) == "fndef" then has_fndef = true) for v in *values

      values = concat [@value v for v in *values], ", "

      if #undeclared == #names and not has_fndef
        @add_line declare..' = '..values
      else
        @add_line declare if #undeclared > 0
        @add_line concat([@value n for n in *names], ", ").." = "..values

  ["return"]: (node) =>
    @add_line "return", @value node[2]

  ["import"]: (node) =>
    _, names, source = unpack node

    to_bind = {}
    get_name = (name) ->
      if ntype(name) == ":"
        tmp = @name name[2]
        to_bind[tmp] = true
        tmp
      else
        @name name

    final_names = [get_name n for n in *names]
    @put_name name for name in *final_names

    get_value = (name) ->
      if to_bind[name]
        moonlib.bind source, name
      else
        source.."."..name

    -- from constant expression, put it on one line
    if type(source) == "string"
      values = [get_value name for name in *final_names]
      @add_line "local", (concat final_names, ", "), "=", (concat values, ", ")
      return nil

    @add_line "local", concat(final_names, ", ")
    @add_line "do"

    inner = @block()
    tmp_name = inner:free_name "table"
    inner:add_line "local", tmp_name , "=", @value source

    source = tmp_name
    inner:add_line name.." = "..get_value name for name in *final_names

    @add_line inner:render()

    @add_line "end"

  ["if"]: (node, ret) =>
    cond, block = node[2], node[3]

    add_clause = (clause) ->
      type = clause[1]
      block = if type == "else"
        @add_line "else"
        clause[2]
      else
        @add_line "elseif", (@value clause[2]), "then"
        clause[3]

      b = @block()
      b:stms block, ret
      @add_line b:render()

    @add_line "if", (@value cond), "then"

    b = @block()
    b:stms block, ret
    @add_line b:render()

    add_clause cond for i, cond in ipairs node when i > 3

    @add_line "end"

  ["while"]: (node) =>
    _, cond, block = unpack node

    @add_line "while", @value(cond), "do"
    inner = @block()
    inner:stms block

    @add_line inner:render()
    @add_line "end"

  comprehension: (node, action) =>
    _, exp, clauses = unpack node

    if not action
      action = @block()
      action:stm exp

    depth = #clauses
    action:set_indent @indent + depth

    render_clause = (clause) =>
      t = clause[1]
      action = @block()
      action:set_indent -1 + @indent

      if "for" == t
        _, names, iter = unpack clause
        name_list = concat [@name name for name in *names], ", "

        if ntype(iter) == "unpack"
          iter = iter[2]
          items_tmp = @free_name "item"
          index_tmp = @free_name "index"

          insert self._lines, 1, ("local %s = %s[%s]"):format name_list, items_tmp, index_tmp

          action:add_lines {
            ("local %s = %s"):format items_tmp, @value iter
            ("for %s=1,#%s do"):format index_tmp, items_tmp
            @render true
            "end"
          }
        else
          action:add_lines {
            ("for %s in %s do"):format(name_list, @value iter)
            @render true
            "end"
          }
      elseif "when" == t
        _, cond = unpack clause
        action:add_lines {
          ("if %s then"):format @value cond
          @render true
          "end"
        }
      else
        error "Unknown comprehension clause: "..t

    render_clause action, clause for i, clause in reversed clauses

    @add_lines action._lines -- do this better?

value_compile =
  exp: (node) =>
    _comp = (i, value) ->
      if i % 2 == 1 and value == "!="
        value = "~="
      @value value

    -- ugly
    concat [_comp i,v for i,v in ipairs node when i > 1], " "

  explist: (node) =>
    concat [@value v for i,v in ipairs node when i > 1], ", "

  parens: (node) =>
    "("..(@value node[2])..")"

  string: (node) =>
    _, delim, inner, delim_end = unpack node
    delim..inner..(delim_end or delim)

  ["if"]: (node) =>
    func = @block()
    func:stm node, returner
    @format "(function()", func:render(), "end)()"

  comprehension: (node) =>
    exp = node[2]
    func = @block()
    tmp_name = func:free_name()

    func:add_line "local", tmp_name, "= {}"

    action = func:block()
    action:add_line ("table.insert(%s, %s)"):format(tmp_name, func:value exp)
    func:stm node, action

    func:add_line "return", tmp_name

    @format "(function()", func:render(), "end)()"

  chain: (node) =>
    callee = node[2]

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

    actions = [chain_item act for i, act in ipairs node when i > 2]

    if ntype(callee) == "self" and node[3] and ntype(node[3]) == "call"
      callee[1] = "self_colon"

    callee_value = @name callee
    callee_value = "("..callee_value..")" if ntype(callee) == "exp"

    return @name(callee)..concat(actions)

  fndef: (node) =>
    _, args, arrow, block = unpack node

    if arrow == "fat"
      insert args, 1, "self"

    b = @block()
    b:put_name name for name in *args
    b:ret_stms block

    decl = "function("..(concat args, ", ")..")"
    if #b._lines == 0
      decl.." end"
    elseif #b._lines == 1
      concat {decl, b._lines[1], "end"}, " "
    else
      @format decl, b._lines, "end"

  table: (node) =>
    _, items = unpack node

    inner = @block() -- handle indent
    _comp = (i, tuple) ->
      out = if #tuple == 2
        key, value = unpack tuple
        key = if type(key) != "string"
          ("[%s]"):format @value key
        else
          @value key
        ("%s = %s"):format key, inner:value value
      else
        inner:value tuple[1]

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

  ["not"]: (node) =>
    "not "..@value node[2]

  self: (node) =>
    "self."..@value node[2]

  self_colon: (node) =>
    "self:"..@value node[2]


block_t = {}
Block = (parent) ->
  indent = parent and parent.indent + 1 or 0
  b = setmetatable {
      _lines: {}, _names: {}, parent: parent
    }, block_t

  b:set_indent indent
  b

B =
  set_indent: (depth) =>
    @indent = depth
    @lead = indent_char:rep @indent

  put_name: (name) =>
    @_names[name] = true

  has_name: (name) =>
    if @_names[name]
      true
    elseif @parent
      @parent:has_name name
    else
      false

  free_name: (prefix) =>
    prefix = prefix or "moon"
    searching = true
    name, i = nil, 0
    while searching
      name = concat {"", prefix, i}, "_"
      i = i + 1
      searching = @has_name name

    @put_name name
    name

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

block_t.__index = B

build_compiler = ->
  Block(nil)
  setmetatable {}, { __index: compiler_index }

_M.tree = (tree) ->
  scope = Block()
  scope:stm line for line in *tree
  scope:render()

