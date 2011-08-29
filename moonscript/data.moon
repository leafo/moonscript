-- data structure utils

module "moonscript.data", package.seeall

export Set, Stack
export ntype, lua_keywords

import concat from table

-- type of node as string
ntype = (node) ->
  if type(node) != "table"
    "value"
  else
    node[1]

Set = (items) ->
  self = {}
  self[key] = true for key in *items
  self

class Stack
  __tostring: => "<Stack {"..concat(self, ", ").."}>"

  new: (...) =>
    @push v for v in *{...}
    nil

  pop: =>
    table.remove self

  push: (value) =>
    table.insert self, value
    value

  top: =>
    self[#self]


lua_keywords = Set{
	'and', 'break', 'do', 'else', 'elseif',
	'end', 'false', 'for', 'function', 'if',
	'in', 'local', 'nil', 'not', 'or',
	'repeat', 'return', 'then', 'true',
	'until', 'while'
}

