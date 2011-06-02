
module "moonscript.compile", package.seeall

util = require "moonscript.util"
data = require "moonscript.data"

import map, bind, itwos, every from util
import Stack from data

B = {}
block_t = {__index: B}

indent_char = "  "
pretty = (lines, indent) ->
  indent = indent or ""
  render = (line) ->
    if type(line) == "table"
      indent_char..pretty(line)
    else
      line

  table.concat [render line for line in *lines], "\n"..indent

block_t = {}
Block = (parent) ->
  indent = parent and parent.indent + 1 or 0
  setmetatable {
      lines: {}, names: {}
      indent: indent, parent: parent
    }, block_t

B =
  put_name: (name) =>
    @names[name] = true

  has_name: (name) =>
    if @names[name]
      true
    elseif @parent
      @parent:has_name name
    else
      false

  add_lines: (lines) =>
    table.insert @lines, line for line in *lines

  add_line: (line) =>
    table.insert @lines, line

  render: =>
    pretty @lines, indent_char:rep @indent

line_compile =
  assign: (node) =>
    "hello world"

value_compile =
  exp: (node) =>
    "yeah"

compiler_index =
  block: (node) =>
    @out = Block(@out)

    @stm s for s in *node

    out = @out
    @out = @out.parent
    out

  name: (node) => @value node

  value: (node) =>
    return tostring node if type node != "table"
    fn = value_compile[node[1]]
    error "Failed to compile value: "..node[1] if not fn

    fn self, node

  values: (values, delim) =>
    delim = delim or ', '
    table.concat [@value v for v in values], delim

  stm: (node) =>
    fn = line_compile[node[1]]
    error "Failed to compile statment: "..node[1] if not fn

    out = fn self, node
    @out:add_line out if out

block_t.__index = B

build_compiler = ->
  setmetatable {}, { __index: compiler_index }

_M.tree = (tree) ->
  compiler = build_compiler()
  compiler:block(tree):render()

