
module("moonscript", package.seeall)

require"util"
require"lpeg"

require"moonscript.compile"

local function count_indent(str)
	local sum = 0
	for v in str:gmatch("[\t ]") do
		if v == ' ' then sum = sum + 1 end
		if v == '\t' then sum = sum + 4 end
	end
	return sum
end

local R, S, V, P = lpeg.R, lpeg.S, lpeg.V, lpeg.P
local C, Ct = lpeg.C, lpeg.Ct

local Space = S" \t"^0
local Break = S"\n" + -1
local Indent = C(S"\t "^0) / count_indent
local ArgDelim = "," * Space

local Name = C(R("az", "AZ", "__") * R("az", "AZ", "__")^0) * Space
local Num = C(R("09")^1) / tonumber * Space

local FactorOp = lpeg.C(S"+-") * Space
local TermOp = lpeg.C(S"*/%") * Space

function wrap(fn)
	local env = getfenv(fi)

	return setfenv(fn, setmetatable({}, {
		__index = function(self, name)
			local value = env[name] 
			if value ~= nil then return value end

			if name:match"^[A-Z][A-Za-z0-9]*$" then
				local v = V(name)
				rawset(self, name, v)
				return v
			end
			error("unknown variable referenced: "..name)
		end
	}))
end

function mark(name)
	return function(...)
		return name, ...
	end
end

function flatten(tbl)
	if #tbl == 1 then
		return tbl[1]
	end
	return tbl
end

local build_grammar = wrap(function()
	local err_msg = "Failed to compile, line:\n [%d] >> %s"
	local line = 1
	local function line_count(subject, pos, str)
		for _ in str:gmatch("\n") do
			line = line + 1
		end
		-- print(line, util.dump(str))
		return true
	end

	local Space = lpeg.Cmt(Space, line_count)
	local Break = lpeg.Cmt(Break, line_count)

	local g = lpeg.P{
		Block,
		Block = Ct(Line^0),
		Line = Ct(Funcall) * Break,
		Funcall = Name * ArgList / mark"fncall",
		ArgList = Ct(Exp * (ArgDelim * Exp)^0),
		Exp = Ct(Value * (FactorOp * Value)^0) / flatten,
		Value = Funcall + Num + Name
	}
	return {
		_g = Space * g * Space * -1,
		match = function(self, str, ...)
			local function get_line(num)
				for line in str:gmatch("(.-)[\n$]") do
					if num == 1 then return line end
					num = num - 1
				end
			end

			local tree = self._g:match(str, ...)
			if not tree then
				return nil, err_msg:format(line, get_line(line))
			end
			return tree
		end
	}
	
end)

local grammar = build_grammar()

local program = [[
if gogo bozango
	print hello_world
]]
-- print hi + world + 2342
-- print 23424
-- ]]


local tree, err = grammar:match(program)
if not tree then error(err) end

print(util.dump(tree))
-- print(compile.tree(tree))

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


