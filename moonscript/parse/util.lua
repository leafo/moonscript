local P, C, S
do
  local _obj_0 = require("lpeg")
  P, C, S = _obj_0.P, _obj_0.C, _obj_0.S
end
local Indent = C(S("\t ") ^ 0) / function(str)
  do
    local sum = 0
    for v in str:gmatch("[\t ]") do
      local _exp_0 = v
      if " " == _exp_0 then
        sum = sum + 1
      elseif "\t" == _exp_0 then
        sum = sum + 4
      end
    end
    return sum
  end
end
local Cut = P(function()
  return false
end)
local ensure
ensure = function(patt, finally)
  return patt * finally + finally * Cut
end
return {
  Indent = Indent,
  Cut = Cut,
  ensure = ensure
}
