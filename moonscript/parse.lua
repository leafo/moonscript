module("moonscript.parse", package.seeall)

local util = require"moonscript.util"

require"lpeg"

local debug_grammar = false

local data = require"moonscript.data"
local types = require"moonscript.types"

local ntype = types.ntype

local dump = util.dump
local trim = util.trim

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
local C, Ct, Cmt, Cg, Cb, Cc = lpeg.C, lpeg.Ct, lpeg.Cmt, lpeg.Cg, lpeg.Cb, lpeg.Cc

lpeg.setmaxstack(10000)

local White = S" \t\r\n"^0
local _Space = S" \t"^0
local Break = P"\r"^-1 * P"\n"
local Stop = Break + -1
local Indent = C(S"\t "^0) / count_indent

local Comment = P"--" * (1 - S"\r\n")^0 * #Stop
local Space = _Space * Comment^-1
local SomeSpace = S" \t"^1 * Comment^-1

local SpaceBreak = Space * Break
local EmptyLine = SpaceBreak

local AlphaNum = R("az", "AZ", "09", "__")

local _Name = C(R("az", "AZ", "__") * AlphaNum^0)
local Name = Space * _Name

local Num = P"0x" * R("09", "af", "AF")^1 +
	R"09"^1 * (P"." * R"09"^1)^-1 * (S"eE" * P"-"^-1 * R"09"^1)^-1

Num = Space * (Num / function(value) return {"number", value} end)

local FactorOp = Space * C(S"+-")
local TermOp = Space * C(S"*/%^")

local Shebang = P"#!" * P(1 - Stop)^0

-- can't have P(false) because it causes preceding patterns not to run
local Cut = P(function() return false end)

local function ensure(patt, finally)
	return patt * finally + finally * Cut
end

-- auto declare Proper variables with lpeg.V
local function wrap_env(fn)
	local env = getfenv(fn)
	local wrap_name = V

	if debug_grammar then
		local indent = 0
		local indent_char = "  "

		local function iprint(...)
			local args = {...}
			for i=1,#args do
				args[i] = tostring(args[i])
			end

			io.stdout:write(indent_char:rep(indent) .. table.concat(args, ", ") .. "\n")
		end

		wrap_name = function(name)
			local v = V(name)
			v = Cmt("", function()
				iprint("* " .. name)
				indent = indent + 1
				return true
			end) * Cmt(v, function(str, pos, ...)
				iprint(name, true)
				indent = indent - 1
				return true, ...
			end) + Cmt("", function()
				iprint(name, false)
				indent = indent - 1
				return false
			end)
			return v
		end
	end

	return setfenv(fn, setmetatable({}, {
		__index = function(self, name)
			local value = env[name]
			if value ~= nil then return value end

			if name:match"^[A-Z][A-Za-z0-9]*$" then
				local v = wrap_name(name)
				rawset(self, name, v)
				return v
			end
			error("unknown variable referenced: "..name)
		end
	}))
end

function extract_line(str, start_pos)
	str = str:sub(start_pos)
	m = str:match"^(.-)\n"
	if m then return m end
	return str:match"^.-$"
end

local function mark(name)
	return function(...)
		return {name, ...}
	end
end

local function insert_pos(pos, value)
    if type(value) == "table" then
        value[-1] = pos
    end
    return value
end

local function pos(patt)
	return (lpeg.Cp() * patt) / insert_pos
end

local function got(what)
	return Cmt("", function(str, pos, ...)
		local cap = {...}
		print("++ got "..what, "["..extract_line(str, pos).."]")
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

-- makes sure the last item in a chain is an index
local _chain_assignable = { index = true, dot = true, slice = true }

local function is_assignable(node)
	local t = ntype(node)
	return t == "self" or t == "value" or t == "self_class" or
		t == "chain" and _chain_assignable[ntype(node[#node])]
end

local function check_assignable(str, pos, value)
	if is_assignable(value) then
		return true, value
	end
	return false
end

local flatten_explist = flatten_or_mark"explist"
local function format_assign(lhs_exps, assign)
	if not assign then
		return flatten_explist(lhs_exps)
	end

	for _, assign_exp in ipairs(lhs_exps) do
		if not is_assignable(assign_exp) then
			error {assign_exp, "left hand expression is not assignable"}
		end
	end

	local t = ntype(assign)
	if t == "assign" then
		return {"assign", lhs_exps, unpack(assign, 2)}
	elseif t == "update" then
		return {"update", lhs_exps[1], unpack(assign, 2)}
	end

	error "unknown assign expression"
end

-- the if statement only takes a single lhs, so we wrap in table to git to
-- "assign" tuple format
local function format_single_assign(lhs, assign)
	if assign then
		return format_assign({lhs}, assign)
	end
	return lhs
end

local function sym(chars)
	return Space * chars
end

local function symx(chars)
	return chars
end

local function simple_string(delim, allow_interpolation)
	local inner = P('\\'..delim) + "\\\\" + (1 - S('\r\n'..delim))
	if allow_interpolation then
		inter = symx"#{" * V"Exp" * sym"}"
		inner = (C((inner - inter)^1) + inter / mark"interpolate")^0
	else
		inner = C(inner^0)
	end

	return C(symx(delim)) *
		inner * sym(delim) / mark"string"
end

local function wrap_func_arg(value)
	return {"call", {value}}
end

-- DOCME
local function flatten_func(callee, args)
	if #args == 0 then return callee end

	args = {"call", args}
	if ntype(callee) == "chain" then
		-- check for colon stub that needs arguments
		if ntype(callee[#callee]) == "colon_stub" then
			local stub = callee[#callee]
			stub[1] = "colon"
			table.insert(stub, args)
		else
			table.insert(callee, args)
		end

		return callee
	end

	return {"chain", callee, args}
end

local function flatten_string_chain(str, chain, args)
	if not chain then return str end
	return flatten_func({"chain", str, unpack(chain)}, args)
end

-- transforms a statement that has a line decorator
local function wrap_decorator(stm, dec)
	if not dec then return stm end
	return { "decorated", stm, dec }
end

-- wrap if statement if there is a conditional decorator
local function wrap_if(stm, cond)
	if cond then
		local pass, fail = unpack(cond)
		if fail then fail = {"else", {fail}} end
		return {"if", cond[2], {stm}, fail}
	end
	return stm
end

local function check_lua_string(str, pos, right, left)
	return #left == #right
end

-- :name in table literal
local function self_assign(name)
	return {{"key_literal", name}, name}
end

local err_msg = "Failed to parse:%s\n [%d] >>    %s"

local build_grammar = wrap_env(function()
	local _indent = Stack(0) -- current indent
	local _do_stack = Stack(0)

	local last_pos = 0 -- used to know where to report error
	local function check_indent(str, pos, indent)
		last_pos = pos
		return _indent:top() == indent
	end

	local function advance_indent(str, pos, indent)
		local top = _indent:top()
		if top ~= -1 and indent > _indent:top() then
			_indent:push(indent)
			return true
		end
	end

	local function push_indent(str, pos, indent)
		_indent:push(indent)
		return true
	end

	local function pop_indent(str, pos)
		if not _indent:pop() then error("unexpected outdent") end
		return true
	end


	local function check_do(str, pos, do_node)
		local top = _do_stack:top()
		if top == nil or top then
			return true, do_node
		end
		return false
	end

	local function disable_do(str_pos)
		_do_stack:push(false)
		return true
	end

	local function enable_do(str_pos)
		_do_stack:push(true)
		return true
	end

	local function pop_do(str, pos)
		if nil == _do_stack:pop() then error("unexpected do pop") end
		return true
	end

	local DisableDo = Cmt("", disable_do)
	local EnableDo = Cmt("", enable_do)
	local PopDo = Cmt("", pop_do)

	local keywords = {}
	local function key(chars)
		keywords[chars] = true
		return Space * chars * -AlphaNum
	end

	local function op(word)
		local patt = Space * C(word)
		if word:match("^%w*$") then
			keywords[word] = true
			patt = patt * -AlphaNum
		end
		return patt
	end

	-- make sure name is not a keyword
	local Name = Cmt(Name, function(str, pos, name)
		if keywords[name] then return false end
		return true
	end) / trim

	local SelfName = Space * "@" * (
		"@" * (_Name / mark"self_class" + Cc"self.__class") +
		_Name / mark"self" + Cc"self")

	local KeyName = SelfName + Space * _Name / mark"key_literal"

	local Name = SelfName + Name + Space * "..." / trim

	local g = lpeg.P{
		File,
		File = Shebang^-1 * (Block + Ct""),
		Block = Ct(Line * (Break^1 * Line)^0),
		CheckIndent = Cmt(Indent, check_indent), -- validates line is in correct indent
		Line = (CheckIndent * Statement + Space * #Stop),

		Statement = pos(
				Import + While + With + For + ForEach + Switch + Return +
				Local + Export + BreakLoop +
				Ct(ExpList) * (Update + Assign)^-1 / format_assign
			) * Space * ((
				-- statement decorators
				key"if" * Exp * (key"else" * Exp)^-1 * Space / mark"if" +
				key"unless" * Exp / mark"unless" +
				CompInner / mark"comprehension"
			) * Space)^-1 / wrap_decorator,

		Body = Space^-1 * Break * EmptyLine^0 * InBlock + Ct(Statement), -- either a statement, or an indented block

		Advance = #Cmt(Indent, advance_indent), -- Advances the indent, gives back whitespace for CheckIndent
		PushIndent = Cmt(Indent, push_indent),
		PreventIndent = Cmt(Cc(-1), push_indent),
		PopIndent = Cmt("", pop_indent),
		InBlock = Advance * Block * PopIndent,

		Local = key"local" * Ct(NameList) / mark"declare_with_shadows",

		Import = key"import" *  Ct(ImportNameList) * key"from" * Exp / mark"import",
		ImportName = (sym"\\" * Ct(Cc"colon_stub" * Name) + Name),
		ImportNameList = ImportName * (sym"," * ImportName)^0,

		NameList = Name * (sym"," * Name)^0,

		BreakLoop = Ct(key"break"/trim) + Ct(key"continue"/trim),

		Return = key"return" * (ExpListLow/mark"explist" + C"") / mark"return",

		WithExp = Ct(ExpList) * Assign^-1 / format_assign,
		With = key"with" * DisableDo * ensure(WithExp, PopDo) * key"do"^-1 * Body / mark"with",

		Switch = key"switch" * DisableDo * ensure(Exp, PopDo) * key"do"^-1 * Space^-1 * Break * SwitchBlock / mark"switch",

		SwitchBlock = EmptyLine^0 * Advance * Ct(SwitchCase * (Break^1 * SwitchCase)^0 * (Break^1 * SwitchElse)^-1) * PopIndent,
		SwitchCase = key"when" * Exp * key"then"^-1 * Body / mark"case",
		SwitchElse = key"else" * Body / mark"else",

		IfCond = Exp * Assign^-1 / format_single_assign,

		If = key"if" * IfCond * key"then"^-1 * Body *
			((Break * CheckIndent)^-1 * EmptyLine^0 * key"elseif" * pos(IfCond) * key"then"^-1 * Body / mark"elseif")^0 *
			((Break * CheckIndent)^-1 * EmptyLine^0 * key"else" * Body / mark"else")^-1 / mark"if",

		Unless = key"unless" * IfCond * key"then"^-1 * Body *
			((Break * CheckIndent)^-1 * EmptyLine^0 * key"else" * Body / mark"else")^-1 / mark"unless",

		While = key"while" * DisableDo * ensure(Exp, PopDo) * key"do"^-1 * Body / mark"while",

		For = key"for" * DisableDo * ensure(Name * sym"=" * Ct(Exp * sym"," * Exp * (sym"," * Exp)^-1), PopDo) *
			key"do"^-1 * Body / mark"for",

		ForEach = key"for" * Ct(NameList) * key"in" * DisableDo * ensure(Ct(sym"*" * Exp / mark"unpack" + ExpList), PopDo) * key"do"^-1 * Body / mark"foreach",

		Do = key"do" * Body / mark"do",

		Comprehension = sym"[" * Exp * CompInner * sym"]" / mark"comprehension",

		TblComprehension = sym"{" * Ct(Exp * (sym"," * Exp)^-1) * CompInner * sym"}" / mark"tblcomprehension",

		CompInner = Ct(CompFor * CompClause^0),
		CompFor = key"for" * Ct(NameList) * key"in" * (sym"*" * Exp / mark"unpack" + Exp) / mark"for",
		CompClause = CompFor + key"when" * Exp / mark"when",

		Assign = sym"=" * (Ct(With + If + Switch) + Ct(TableBlock + ExpListLow)) / mark"assign",
		Update = ((sym"..=" + sym"+=" + sym"-=" + sym"*=" + sym"/=" + sym"%=" + sym"or=" + sym"and=") / trim) * Exp / mark"update",

		-- we can ignore precedence for now
		OtherOps = op"or" + op"and" + op"<=" + op">=" + op"~=" + op"!=" + op"==" + op".." + op"<" + op">",

		Assignable = Cmt(DotChain + Chain, check_assignable) + Name,
		AssignableList = Assignable * (sym"," * Assignable)^0,

		Exp = Ct(Value * ((OtherOps + FactorOp + TermOp) * Value)^0) / flatten_or_mark"exp",

		-- Exp = Ct(Factor * (OtherOps * Factor)^0) / flatten_or_mark"exp",
		-- Factor = Ct(Term * (FactorOp * Term)^0) / flatten_or_mark"exp",
		-- Term = Ct(Value * (TermOp * Value)^0) / flatten_or_mark"exp",

		SimpleValue =
			If + Unless +
			Switch +
			With +
			ClassDecl +
			ForEach + For + While +
			Cmt(Do, check_do) +
			sym"-" * -SomeSpace * Exp / mark"minus" +
			sym"#" * Exp / mark"length" +
			key"not" * Exp / mark"not" +
			TblComprehension +
			TableLit +
			Comprehension +
			FunLit +
			Num,

		ChainValue = -- a function call or an object access
			StringChain +
			((Chain + DotChain + Callable) * Ct(InvokeArgs^-1)) / flatten_func,

		Value = pos(
			SimpleValue +
			Ct(KeyValueList) / mark"table" +
			ChainValue),

		SliceValue = SimpleValue + ChainValue,

		StringChain = String *
			(Ct((ColonCall + ColonSuffix) * ChainTail^-1) * Ct(InvokeArgs^-1))^-1 / flatten_string_chain,

		String = Space * DoubleString + Space * SingleString + LuaString,
		SingleString = simple_string("'"),
		DoubleString = simple_string('"', true),

		LuaString = Cg(LuaStringOpen, "string_open") * Cb"string_open" * Break^-1 *
			C((1 - Cmt(C(LuaStringClose) * Cb"string_open", check_lua_string))^0) *
			LuaStringClose / mark"string",

		LuaStringOpen = sym"[" * P"="^0 * "[" / trim,
		LuaStringClose = "]" * P"="^0 * "]",

		Callable = Name + Parens / mark"parens",
		Parens = sym"(" * Exp * sym")",

		FnArgs = symx"(" * Ct(ExpList^-1) * sym")" + sym"!" * -P"=" * Ct"",

		ChainTail = ChainItem^1 * ColonSuffix^-1 + ColonSuffix,

		-- a list of funcalls and indexes on a callable
		Chain = Callable * ChainTail / mark"chain",

		-- shorthand dot call for use in with statement
		DotChain =
			(sym"." * Cc(-1) * (_Name / mark"dot") * ChainTail^-1) / mark"chain" +
			(sym"\\" * Cc(-1) * (
				(_Name * Invoke / mark"colon") * ChainTail^-1 +
				(_Name / mark"colon_stub")
			)) / mark"chain",

		ChainItem =
			Invoke +
			Slice +
			symx"[" * Exp/mark"index" * sym"]" +
			symx"." * _Name/mark"dot" +
			ColonCall,

		Slice = symx"[" * (SliceValue + Cc(1)) * sym"," * (SliceValue + Cc"")  *
			(sym"," * SliceValue)^-1 *sym"]" / mark"slice",

		ColonCall = symx"\\" * (_Name * Invoke) / mark"colon",
		ColonSuffix = symx"\\" * _Name / mark"colon_stub",

		Invoke = FnArgs/mark"call" +
			SingleString / wrap_func_arg +
			DoubleString / wrap_func_arg,

		TableValue = KeyValue + Ct(Exp),

		TableLit = sym"{" * Ct(
				TableValueList^-1 * sym","^-1 *
				(SpaceBreak * TableLitLine * (sym","^-1 * SpaceBreak * TableLitLine)^0 * sym","^-1)^-1
			) * White * sym"}" / mark"table",

		TableValueList = TableValue * (sym"," * TableValue)^0,
		TableLitLine = PushIndent * ((TableValueList * PopIndent) + (PopIndent * Cut)) + Space,

		-- the unbounded table
		TableBlockInner = Ct(KeyValueLine * (SpaceBreak^1 * KeyValueLine)^0),
		TableBlock = SpaceBreak^1 * Advance * ensure(TableBlockInner, PopIndent) / mark"table",

		ClassDecl = key"class" * (Assignable + Cc(nil)) * (key"extends" * PreventIndent * ensure(Exp, PopIndent) + C"")^-1 * (ClassBlock + Ct("")) / mark"class",

		ClassBlock = SpaceBreak^1 * Advance *
			Ct(ClassLine * (SpaceBreak^1 * ClassLine)^0) * PopIndent,
		ClassLine = CheckIndent * ((
				KeyValueList / mark"props" +
				Statement / mark"stm" +
				Exp / mark"stm"
			) * sym","^-1),

		Export = key"export" * (
			Cc"class" * ClassDecl +
			op"*" + op"^" +
			Ct(NameList) * (sym"=" * Ct(ExpListLow))^-1) / mark"export",

		KeyValue = (sym":" * Name) / self_assign + Ct((KeyName + sym"[" * Exp * sym"]" + DoubleString + SingleString) * symx":" * (Exp + TableBlock)),
		KeyValueList = KeyValue * (sym"," * KeyValue)^0,
		KeyValueLine = CheckIndent * KeyValueList * sym","^-1,

		FnArgsDef = sym"(" * Ct(FnArgDefList^-1) *
			(key"using" * Ct(NameList + Space * "nil") + Ct"") *
			sym")" + Ct"" * Ct"",

		FnArgDefList =  FnArgDef * (sym"," * FnArgDef)^0,
		FnArgDef = Ct(Name * (sym"=" * Exp)^-1),

		FunLit = FnArgsDef *
			(sym"->" * Cc"slim" + sym"=>" * Cc"fat") *
			(Body + Ct"") / mark"fndef",

		NameList = Name * (sym"," * Name)^0,
		ExpList = Exp * (sym"," * Exp)^0,
		ExpListLow = Exp * ((sym"," + sym";") * Exp)^0,

		InvokeArgs = ExpList * (sym"," * (TableBlock + SpaceBreak * Advance * ArgBlock * TableBlock^-1) + TableBlock)^-1 + TableBlock,
		ArgBlock = ArgLine * (sym"," * SpaceBreak * ArgLine)^0 * PopIndent,
		ArgLine = CheckIndent * ExpList
	}

	return {
		_g = White * g * White * -1,
		match = function(self, str, ...)

			local pos_to_line = function(pos)
				return util.pos_to_line(str, pos)
			end

			local get_line = function(num)
				return util.get_line(str, num)
			end

			local tree
			local pass, err = pcall(function(...)
				tree = self._g:match(str, ...)
			end, ...)

			-- regular error, let it bubble up
			if type(err) == "string" then
				error(err)
			end

			if not tree then
				local pos = last_pos
				local msg

				if err then
					local node
					node, msg = unpack(err)
					msg = msg and " " .. msg
					pos = node[-1]
				end

				local line_no = pos_to_line(pos)
				local line_str = get_line(line_no) or ""

				return nil, err_msg:format(msg or "", line_no, trim(line_str))
			end
			return tree
		end
	}

end)

-- parse a string
-- returns tree, or nil and error message
function string(str)
	local g = build_grammar()
	return g:match(str)
end

