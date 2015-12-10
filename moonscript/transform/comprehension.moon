
import is_value from require "moonscript.types"

construct_comprehension = (inner, clauses) ->
  current_stms = inner
  for i=#clauses,1,-1
    clause = clauses[i]
    t = clause[1]

    current_stms = switch t
      when "for"
        {_, name, bounds} = clause
        {"for", name, bounds, current_stms}
      when "foreach"
        {_, names, iter} = clause
        {"foreach", names, {iter}, current_stms}
      when "when"
        {_, cond} = clause
        {"if", cond, current_stms}
      else
        error "Unknown comprehension clause: "..t

    current_stms = {current_stms}

  current_stms[1]

comprehension_has_value = (comp) ->
  is_value comp[2]

{:construct_comprehension, :comprehension_has_value}
