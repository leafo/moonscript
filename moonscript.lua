
module("moonscript", package.seeall)

require"util"
require"lpeg"

require"moonscript.compile"
require"moonscript.dump"
require"moonscript.data"

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

local Space = S" \t"^0
local Break = S"\n"
local Stop = Break + -1
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

function got(what)
	return function(...)
		print("got "..tostring(what))
		return true
	end
end


function flatten(tbl)
	if #tbl == 1 then
		return tbl[1]
	end
	return tbl
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

	local g = lpeg.P{
		Block,
		Block = Ct((Line)^0),
		Line = Break + Cmt(Indent, check_indent) * (Ct(If) + Exp * Stop),
		InBlock = #Cmt(Indent, advance_indent) * Block * OutBlock,
		OutBlock = Cmt(P(""), pop_indent),

		Funcall = Name * ArgList / mark"fncall",
		If = key"if" * Exp * Break * InBlock / mark "if",

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
				return nil, err_msg:format(line, get_line(line), _indent:top())
			end
			return tree
		end
	}
	
end)

local grammar = build_grammar()



local program = [[
if two_dads
	do something
	if yum
		heckyes 23

print 2

print dadas
this is what a sentence does when you use it
]]


local tree, err = grammar:match(program)
if not tree then error(err) end

dump.tree(tree)
print""
print(compile.tree(tree))

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


