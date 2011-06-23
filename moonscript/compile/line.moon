module "moonscript.compile", package.seeall

util = require "moonscript.util"
data = require "moonscript.data"
dump = require "moonscript.dump"

require "moonscript.compile.format"

import reversed from util
import ntype from data
import concat, insert from table

export line_compile

constructor_name = "new"

line_compile =
  raw: (node) =>
    _, text = unpack node
    @add_line text
  assign: (node) =>
    _, names, values = unpack node

    undeclared = @declare names
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

  update: (node) =>
    _, name, op, exp = unpack node
    op_final = op\match "(.)="
    error"unknown op: "..op if not op_final
    @stm {"assign", {name}, {{"exp", name, op_final, exp}}}

  return: (node) =>
    @add_line "return", @value node[2]

  break: (node) =>
    @add_line "break"

  import: (node) =>
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
    tmp_name = inner\free_name "table"
    inner\add_line "local", tmp_name , "=", @value source

    source = tmp_name
    inner\add_line name.." = "..get_value name for name in *final_names

    @add_line inner\render!

    @add_line "end"

  if: (node, ret) =>
    cond, block = node[2], node[3]

    add_clause = (clause) ->
      type = clause[1]
      block = if type == "else"
        @add_line "else"
        clause[2]
      else
        @add_line "elseif", (@value clause[2]), "then"
        clause[3]

      b = @block!
      b\stms block, ret
      @add_line b\render!

    @add_line "if", (@value cond), "then"

    b = @block!
    b\stms block, ret
    @add_line b\render!

    add_clause cond for i, cond in ipairs node when i > 3

    @add_line "end"

  while: (node) =>
    _, cond, block = unpack node

    inner = @block!
    if is_non_atomic cond
      @add_line "while", "true", "do"
      inner\stm {"if", {"not", cond}, {{"break"}}}
    else
      @add_line "while", @value(cond), "do"

    inner\stms block

    @add_line inner\render!
    @add_line "end"

  for: (node) =>
    _, name, bounds, block = unpack node
    bounds = @value {"explist", unpack bounds}
    @add_line "for", @name(name), "=", bounds, "do"
    inner = @block!
    inner\stms block
    @add_line inner\render!
    @add_line "end"

  export: (node) =>
    _, names = unpack node
    @put_name name for name in *names when type(name) == "string"
    nil

  class: (node) =>
    _, name, parent_val, tbl = unpack node

    constructor = nil
    final_properties = {}

    find_special = (name, value) ->
      if name == constructor_name
        constructor = value
      else
        insert final_properties, {name, value}

    find_special unpack entry for entry in *tbl[2]
    tbl[2] = final_properties

    def_scope = @block!
    parent_loc = def_scope\free_name "parent"

    def_scope\set "super" (block, chain) ->
      calling_name = block\get"current_block"
      slice = [item for i, item in ipairs chain when i > 2]
      -- inject self
      slice[1] = {"call", {"self", unpack slice[1][2]}}

      {"chain", parent_loc, {"dot", calling_name}, unpack slice}

    -- synthesize constructor if needed
    if not constructor
      constructor = {"fndef", {"..."}, "fat", {
        {"if", parent_loc, {
          {"chain", "super", {"call", {"..."}}}
        }}
      }}

    -- organize constructor
    -- extract self arguments
    self_args = {}
    get_initializers = (arg) ->
      if ntype(arg) == "self"
        arg = arg[2]
        insert self_args, arg
      arg

    constructor[2] = [get_initializers arg for arg in *constructor[2]]
    constructor[3] = "fat"
    body = constructor[4]

    -- insert self assigning arguments
    dests = [{"self", name} for name in *self_args]
    insert body, 1, {"assign", dests, self_args} if #self_args > 0

    base_name = def_scope\free_name "base"
    def_scope\add_line ("local %s =")\format(base_name), def_scope\value tbl
    def_scope\add_line ("%s.__index = %s")\format(base_name, base_name)

    cls = def_scope\value {"table", {
      {"__init", constructor}
    }}

    cls_mt = def_scope\value {"table", {
      {"__index", base_name}
      {"__call", {"fndef", {"mt", "..."}, "slim", {
          {"raw", ("local self = setmetatable({}, %s)")\format(base_name)}
          {"chain", "mt.__init", {"call", {"self", "..."}}}
          "self"
        }}}
    }}

    if parent_val != ""
      def_scope\stm {"if", parent_loc,
        {{"chain", "setmetatable", {"call",
        {base_name, {"chain", "getmetatable",
          {"call", {parent_loc}}, {"dot", "__index"}}}}}}}

    def_scope\add_line ("return setmetatable(%s, %s)")\format(cls, cls_mt)

    parent_val = @value parent_val if parent_val != ""

    def = concat {
      ("(function(%s)\n")\format(parent_loc)
      def_scope\render()
      ("\nend)(%s)")\format(parent_val)
    }

    @add_line "local", name
    @put_name name
    @stm {"assign", {name}, {def}}

  comprehension: (node, action) =>
    _, exp, clauses = unpack node

    if not action
      action = @block!
      action\stm exp

    depth = #clauses
    action\set_indent @indent + depth

    render_clause = (clause) =>
      t = clause[1]
      action = @block()
      action\set_indent @indent - 1

      if "for" == t
        _, names, iter = unpack clause
        name_list = concat [@name name for name in *names], ", "

        if ntype(iter) == "unpack"
          iter = iter[2]
          items_tmp = @free_name "item"
          index_tmp = @free_name "index"

          insert self._lines, 1, ("local %s = %s[%s]")\format name_list, items_tmp, index_tmp

          action\add_lines {
            ("local %s = %s")\format items_tmp, @value iter
            ("for %s=1,#%s do")\format index_tmp, items_tmp
            @render true
            "end"
          }
        else
          action\add_lines {
            ("for %s in %s do")\format(name_list, @value iter)
            @render true
            "end"
          }
      elseif "when" == t
        _, cond = unpack clause
        action\add_lines {
          ("if %s then")\format @value cond
          @render true
          "end"
        }
      else
        error "Unknown comprehension clause: "..t

    render_clause action, clause for i, clause in reversed clauses

    @add_lines action._lines -- do this better?

  with: (node, ret) =>
    _, exp, block = unpack node
    inner = @block!
    tmp_name = inner\free_name "with", true

    @set "scope_var", tmp_name
    inner\stm {"assign", {tmp_name}, {exp}}
    inner\stms block
    inner\stm ret tmp_name if ret

    @add_line "do"
    @add_line inner\render!
    @add_line "end"

