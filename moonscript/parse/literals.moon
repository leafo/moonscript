-- non-recursive parsers
import safe_module from require "moonscript.util"
import S, P, R, C from require "lpeg"

lpeg = require "lpeg"
L = lpeg.luversion and lpeg.L or (v) -> #v

White = S" \t\r\n"^0
plain_space = S" \t"^0

Break = P"\r"^-1 * P"\n"
Stop = Break + -1

Comment = P"--" * (1 - S"\r\n")^0 * L(Stop)
Space = plain_space * Comment^-1
SomeSpace = S" \t"^1 * Comment^-1

SpaceBreak = Space * Break
EmptyLine = SpaceBreak

AlphaNum = R "az", "AZ", "09", "__"

Name = C R("az", "AZ", "__") * AlphaNum^0

Num = P"0x" * R("09", "af", "AF")^1 * (S"uU"^-1 * S"lL"^2)^-1 +
  R"09"^1 * (S"uU"^-1 * S"lL"^2) +
  (
    R"09"^1 * (P"." * R"09"^1)^-1 +
    P"." * R"09"^1
  ) * (S"eE" * P"-"^-1 * R"09"^1)^-1

Shebang = P"#!" * P(1 - Stop)^0

safe_module "moonscript.parse.literals", {
  :L
  :White, :Break, :Stop, :Comment, :Space, :SomeSpace, :SpaceBreak, :EmptyLine,
  :AlphaNum, :Name, :Num, :Shebang
}
