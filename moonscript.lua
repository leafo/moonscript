
module("moonscript", package.seeall)

require"util"
require"lpeg"

local R, S, V, P = lpeg.R, lpeg.S, lpeg.V, lpeg.P
local C, Ct = lpeg.C, lpeg.Ct

local Space = S" \n\t"^0
local Indent = S"\t"^0
local Break = S"\n"^1

local Name = C(R("az", "AZ", "__") * R("az", "AZ", "__")^0) * Space
local Num = C(R("09")^1) * Space

local FactorOp = lpeg.C(S"+-") * Space
local TermOp = lpeg.C(S"*/%") * Space

function define(items)
	for _, name in ipairs(items) do
		_G[name] = lpeg.V(name)
	end
end

define { "Block", "Line", "Value", "Exp", "Factor", "Term" }

local grammar = lpeg.P{
	Block,
	Block = Ct(Line^0),
	Line = Ct(C"print" * Space * Exp * Space),
	Exp = Ct(Value * (FactorOp * Value)^0),
	Value = Num + Name
}
grammar = Space * grammar * Space * -1

local program = [[
print 2323
print hi + world + 2342
print 23424
]]

print(util.dump(grammar:match(program)))

local program2 = [[
if something
	print 1
else
	print 2
]]

local program2_ = [[
if something
{ print 1
} else
{ print 2
}
]]

local program3 = [[
class Hello
	@something = 2323

	hello: () ->
		print 200
]]

local program3 = [[
class Hello
{ @something = 2323
  hello: () ->
  { print 200
}}
]]


function names()
	tests = {
		"hello",
		"23wolrld",
		"_What343"
	}

	for _, v in ipairs(tests) do
		print(Name:match(v))
	end
end


