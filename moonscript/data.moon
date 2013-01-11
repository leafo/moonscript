-- data structures & static data

import concat, remove, insert from table

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
    remove self

  push: (value) =>
    insert self, value
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

{ :Set, :Stack, :lua_keywords }

