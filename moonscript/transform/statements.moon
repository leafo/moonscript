
types = require "moonscript.types"
import ntype, mtype, is_value, NOOP from types

import comprehension_has_value from require "moonscript.transform.comprehension"

import insert from table

-- A Run is a special statement node that lets a function run and mutate the
-- state of the compiler
class Run
  new: (@fn) =>
    @[1] = "run"

  call: (state) =>
    @.fn state

-- extract the last statment from an array of statements
-- is group aware
-- returns: the last statement, the index, the table it was fetched from
last_stm = (stms) ->
  last_exp_id = 0
  for i = #stms, 1, -1
    stm = stms[i]
    if stm and mtype(stm) != Run
      if ntype(stm) == "group"
        return last_stm stm[2]

      last_exp_id = i
      break

  stms[last_exp_id], last_exp_id, stms

-- transform the last stm is a list of stms
-- will puke on group
transform_last_stm = (stms, fn) ->
  _, last_idx, _stms = last_stm stms

  if _stms != stms
    error "cannot transform last node in group"

  return for i, stm in ipairs stms
    if i == last_idx
      {"transform", stm, fn}
    else
      stm

chain_is_stub = (chain) ->
  stub = chain[#chain]
  stub and ntype(stub) == "colon"

-- nodes that a continue statement binds to, a continue found inside one of
-- these belongs to that construct and not the enclosing loop
continue_boundaries = {
  fndef: true
  while: true
  for: true
  foreach: true
  comprehension: true
  tblcomprehension: true
}

-- collect the continue nodes in a body that bind to the enclosing loop
find_continues = (tbl, out={}) ->
  for item in *tbl
    if type(item) == "table"
      if item[1] == "continue"
        insert out, item
      elseif not continue_boundaries[item[1]]
        find_continues item, out
  out

-- does a body reference the enclosing function's varargs. Nested functions
-- have their own varargs, string nodes hold literal text at string positions
has_varargs = (tbl) ->
  for item in *tbl
    switch type item
      when "string"
        return true if item == "..."
      when "table"
        switch item[1]
          when "fndef"
            continue
          when "string"
            for i = 3, #item
              part = item[i]
              if type(part) == "table" and has_varargs part
                return true
          else
            return true if has_varargs item
  false

implicitly_return = (scope) ->
  is_top = true
  fn = (stm) ->
    t = ntype stm

    -- expand decorated
    if t == "decorated"
      stm = scope.transform.statement stm
      t = ntype stm

    if types.cascading[t]
      is_top = false
      scope.transform.statement stm, fn
    elseif types.manual_return[t] or not is_value stm
      -- remove blank return statement
      if is_top and t == "return" and stm[2] == ""
        NOOP
      else
        stm
    else
      if t == "comprehension" and not comprehension_has_value stm
        stm
      else
        {"return", stm}

  fn

{:Run, :last_stm, :transform_last_stm, :chain_is_stub, :implicitly_return,
  :find_continues, :has_varargs }

