
types = require "moonscript.types"
import ntype, mtype, is_value, NOOP from types

import comprehension_has_value from require "moonscript.transform.comprehension"

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

{:Run, :last_stm, :transform_last_stm, :chain_is_stub, :implicitly_return }

