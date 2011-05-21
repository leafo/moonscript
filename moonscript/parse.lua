
module("moonscript.parse", package.seeall)

require"util"
require"lpeg"

local compile = require"moonscript.compile"
local dump = require"moonscript.dump"
local data = require"moonscript.data"

local Stack = data.Stack

local function count_indent(str)
	local sum = 0
	for v in str:gmatch("[\t ]") do
		if v == ' ' then sum = sum + 1 end
		if v == '\t' then sum = sum + 4 end
	end
	return sum
end

local R, S, V, P = lpeg.R, lpeg.S, lpeg.V, lpeg.P
local C, Ct, Cmt = lpeg.C, lpeg.Ct, lpeg.Cmt

local White = S" \t\n"^0
local Space = S" \t"^0
local Break = S"\n"
local Stop = Break + -1
local Indent = C(S"\t "^0) / count_indent

local Name = C(R("az", "AZ", "__") * R("az", "AZ", "__")^0) * Space
local Num = C(R("09")^1) / tonumber * Space

local FactorOp = lpeg.C(S"+-") * Space
local TermOp = lpeg.C(S"*/%") * Space

local function wrap(fn)
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

local function mark(name)
	return function(...)
		return {name, ...}
	end
end

local function got(what)
	return Cmt("", function(...)
		print("++ got "..what)
		return true
	end)
end

local function flatten(tbl)
	if #tbl == 1 then
		return tbl[1]
	end
	return tbl
end

local function flatten_or_mark(name)
	return function(tbl)
		if #tbl == 1 then return tbl[1] end
		table.insert(tbl, 1, name)
		return tbl
	end
end

local build_grammar = wrap(function()
	local err_msg = "Failed to compile, line:\n [%d] >> %s (%d)"
	local line = 1
	local function line_count(subject, pos, str)
		for _ in str:gmatch("\n") do
			line = line + 1
		end
		-- print(line, util.dump(str))
		return true
	end

	local Space = Cmt(Space, line_count)
	local Break = Cmt(Break, line_count)

	local _indent = Stack(0) -- current indent

	local function check_indent(str, pos, indent)
		return _indent:top() == indent
	end

	local function advance_indent(str, pos, indent)
		if indent > _indent:top() then
			_indent:push(indent)
			return true
		end
	end

	local function pop_indent(str, pos)
		if not _indent:pop() then error("unexpected outdent") end
		return true
	end

	local keywords = {}
	local function key(word)
		keywords[word] = true
		return word * Space
	end

	local function sym(chars)
		return chars * Space
	end

	-- make sure name is not a keyword
	local Name = Cmt(Name, function(str, pos, name)
		if keywords[name] then return false end
		return true, name
	end)

	local g = lpeg.P{
		File,
		File = Block^-1,
		Block = Ct(Line * (Break^0 * Line)^0),
		Line = Cmt(Indent, check_indent) * (Ct(If) + Exp),

		Body = Break * InBlock + Ct(Line),

		InBlock = #Cmt(Indent, advance_indent) * Block * OutBlock,
		OutBlock = Cmt(P(""), pop_indent),

		FunCall = Name * Ct(ExpList) / mark"fncall",
		If = key"if" * Exp * Body / mark"if",

		Assign = Ct(NameList) * sym"=" * Ct(ExpList) / mark"assign",

		Exp = Ct(Term * (FactorOp * Term)^0) / flatten_or_mark"exp",
		Term = Ct(Value * (TermOp * Value)^0) / flatten_or_mark"exp",
		Value = Assign + FunLit + FunCall + Num + Name + TableLit,

		TableLit = sym"{" * Ct(ExpList^-1) * sym"}" / mark"list",

		FunLit = (sym"(" * Ct(NameList^-1) * sym")" + Ct("")) * sym"->" * Body / mark"fndef",

		NameList = Name * (sym"," * Name)^0,
		ExpList = Exp * (sym"," * Exp)^0
	}

	return {
		_g = White * g * White * -1,
		match = function(self, str, ...)
			local function get_line(num)
				for line in str:gmatch("(.-)[\n$]") do
					if num == 1 then return line end
					num = num - 1
				end
			end

			local tree = self._g:match(str, ...)
			if not tree then
				local line_str = get_line(line) or ""
				return nil, err_msg:format(line, line_str, _indent:top())
			end
			return tree
		end
	}
	
end)

local grammar = build_grammar()

-- parse a string
-- returns tree, or nil and error message
function string(str)
	local g = build_grammar()
	return grammar:match(str)
end


local program = [[
if two_dads
	do something
	if yum
		heckyes 23

print 2

print dadas

{1,2,3,4}

(a,b) ->
	throw nuts

print 100

]]

local program = [[

hi = (a) -> print a

if true
	hi 100

]]

local program3 = [[
-- hello
class Hello
	@something = 2323

	hello: () ->
		print 200
]]

