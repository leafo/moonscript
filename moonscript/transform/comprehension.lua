local is_value
is_value = require("moonscript.types").is_value
local construct_comprehension
construct_comprehension = function(inner, clauses)
  local current_stms = inner
  for i = #clauses, 1, -1 do
    local clause = clauses[i]
    local t = clause[1]
    local _exp_0 = t
    if "for" == _exp_0 then
      local _, name, bounds
      _, name, bounds = clause[1], clause[2], clause[3]
      current_stms = {
        "for",
        name,
        bounds,
        current_stms
      }
    elseif "foreach" == _exp_0 then
      local _, names, iter
      _, names, iter = clause[1], clause[2], clause[3]
      current_stms = {
        "foreach",
        names,
        {
          iter
        },
        current_stms
      }
    elseif "when" == _exp_0 then
      local _, cond
      _, cond = clause[1], clause[2]
      current_stms = {
        "if",
        cond,
        current_stms
      }
    else
      current_stms = error("Unknown comprehension clause: " .. t)
    end
    current_stms = {
      current_stms
    }
  end
  return current_stms[1]
end
local comprehension_has_value
comprehension_has_value = function(comp)
  return is_value(comp[2])
end
return {
  construct_comprehension = construct_comprehension,
  comprehension_has_value = comprehension_has_value
}
