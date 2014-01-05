-- data structures & static data

import concat, remove, insert from table

Set = (items) -> {k,true for k in *items}

class Stack
  __tostring: => "<Stack {"..concat(self, ", ").."}>"

  new: (...) =>
    @push ...
    nil

  pop: =>
    remove @

  push: (value, ...) =>
    insert @, value
    if ...
      @push ...
    else
      value

  top: =>
    self[#self]


lua_keywords = Set {
	'and', 'break', 'do', 'else', 'elseif',
	'end', 'false', 'for', 'function', 'if',
	'in', 'local', 'nil', 'not', 'or',
	'repeat', 'return', 'then', 'true',
	'until', 'while'
}

{ :Set, :Stack, :lua_keywords }

