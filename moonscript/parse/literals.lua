local safe_module
safe_module = require("moonscript.util").safe_module
local S, P, R, C
do
  local _obj_0 = require("lpeg")
  S, P, R, C = _obj_0.S, _obj_0.P, _obj_0.R, _obj_0.C
end
local lpeg = require("lpeg")
local L = lpeg.luversion and lpeg.L or function(v)
  return #v
end
local White = S(" \t\r\n") ^ 0
local plain_space = S(" \t") ^ 0
local Break = P("\r") ^ -1 * P("\n")
local Stop = Break + -1
local Comment = P("--") * (1 - S("\r\n")) ^ 0 * L(Stop)
local Space = plain_space * Comment ^ -1
local SomeSpace = S(" \t") ^ 1 * Comment ^ -1
local SpaceBreak = Space * Break
local EmptyLine = SpaceBreak
local AlphaNum = R("az", "AZ", "09", "__")
local Name = C(R("az", "AZ", "__") * AlphaNum ^ 0)
local Num = P("0x") * R("09", "af", "AF") ^ 1 * (S("uU") ^ -1 * S("lL") ^ 2) ^ -1 + R("09") ^ 1 * (S("uU") ^ -1 * S("lL") ^ 2) + (R("09") ^ 1 * (P(".") * R("09") ^ 1) ^ -1 + P(".") * R("09") ^ 1) * (S("eE") * P("-") ^ -1 * R("09") ^ 1) ^ -1
local Shebang = P("#!") * P(1 - Stop) ^ 0
return safe_module("moonscript.parse.literals", {
  L = L,
  White = White,
  Break = Break,
  Stop = Stop,
  Comment = Comment,
  Space = Space,
  SomeSpace = SomeSpace,
  SpaceBreak = SpaceBreak,
  EmptyLine = EmptyLine,
  AlphaNum = AlphaNum,
  Name = Name,
  Num = Num,
  Shebang = Shebang
})
