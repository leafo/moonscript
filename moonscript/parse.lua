local debug_grammar = false

local lpeg = require"lpeg"

lpeg.setmaxstack(10000)

local util = require"moonscript.util"
local data = require"moonscript.data"
local types = require"moonscript.types"
local literals = require "moonscript.parse.literals"
local parse_util = require "moonscript.parse.util"

local ntype = types.ntype
local trim = util.trim

local wrap_env = require("moonscript.parse.env").wrap_env

local unpack = util.unpack

local Stack = data.Stack

local R, S, V, P = lpeg.R, lpeg.S, lpeg.V, lpeg.P
local C, Ct, Cmt, Cg, Cb, Cc = lpeg.C, lpeg.Ct, lpeg.Cmt, lpeg.Cg, lpeg.Cb, lpeg.Cc

local White = literals.White
local Break = literals.Break
local Stop = literals.Stop
local Comment = literals.Comment
local Space = literals.Space
local SomeSpace = literals.SomeSpace
local SpaceBreak = literals.SpaceBreak
local EmptyLine = literals.EmptyLine
local AlphaNum = literals.AlphaNum
local _Name = literals.Name
local Num = literals.Num
local Shebang = literals.Shebang

local Name = Space * _Name
Num = Space * (Num / function(value) return {"number", value} end)

local Indent = parse_util.Indent
local Cut = parse_util.Cut
local ensure = parse_util.ensure
local extract_line = parse_util.extract_line
local mark = parse_util.mark
local pos = parse_util.pos
local got = parse_util.got
local flatten_or_mark = parse_util.flatten_or_mark
local is_assignable = parse_util.is_assignable
local check_assignable = parse_util.check_assignable
local format_assign = parse_util.format_assign
local format_single_assign = parse_util.format_single_assign
local sym = parse_util.sym
local symx = parse_util.symx
local simple_string = parse_util.simple_string
local wrap_func_arg = parse_util.wrap_func_arg
local flatten_func = parse_util.flatten_func
local flatten_string_chain = parse_util.flatten_string_chain
local wrap_decorator = parse_util.wrap_decorator
local check_lua_string = parse_util.check_lua_string
local self_assign = parse_util.self_assign

local err_msg = "Failed to parse:%s\n [%d] >>    %s"

local build_grammar = wrap_env(debug_grammar, function()
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

	local function pop_do(str, pos)
		if nil == _do_stack:pop() then error("unexpected do pop") end
		return true
	end

	local DisableDo = Cmt("", disable_do)
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
	local VarArg = Space * P"..." / trim

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

		Local = key"local" * ((op"*" + op"^") / mark"declare_glob" + Ct(NameList) / mark"declare_with_shadows"),

		Import = key"import" * Ct(ImportNameList) * SpaceBreak^0 * key"from" * Exp / mark"import",
		ImportName = (sym"\\" * Ct(Cc"colon_stub" * Name) + Name),
		ImportNameList = SpaceBreak^0 * ImportName * ((SpaceBreak^1 + sym"," * SpaceBreak^0) * ImportName)^0,

		BreakLoop = Ct(key"break"/trim) + Ct(key"continue"/trim),

		Return = key"return" * (ExpListLow/mark"explist" + C"") / mark"return",

		WithExp = Ct(ExpList) * Assign^-1 / format_assign,
		With = key"with" * DisableDo * ensure(WithExp, PopDo) * key"do"^-1 * Body / mark"with",

		Switch = key"switch" * DisableDo * ensure(Exp, PopDo) * key"do"^-1 * Space^-1 * Break * SwitchBlock / mark"switch",

		SwitchBlock = EmptyLine^0 * Advance * Ct(SwitchCase * (Break^1 * SwitchCase)^0 * (Break^1 * SwitchElse)^-1) * PopIndent,
		SwitchCase = key"when" * Ct(ExpList) * key"then"^-1 * Body / mark"case",
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

		ForEach = key"for" * Ct(AssignableNameList) * key"in" * DisableDo * ensure(Ct(sym"*" * Exp / mark"unpack" + ExpList), PopDo) * key"do"^-1 * Body / mark"foreach",

		Do = key"do" * Body / mark"do",

		Comprehension = sym"[" * Exp * CompInner * sym"]" / mark"comprehension",

		TblComprehension = sym"{" * Ct(Exp * (sym"," * Exp)^-1) * CompInner * sym"}" / mark"tblcomprehension",

		CompInner = Ct((CompForEach + CompFor) * CompClause^0),
		CompForEach = key"for" * Ct(NameList) * key"in" * (sym"*" * Exp / mark"unpack" + Exp) / mark"foreach",
		CompFor = key "for" * Name * sym"=" * Ct(Exp * sym"," * Exp * (sym"," * Exp)^-1) / mark"for",
		CompClause = CompFor + CompForEach + key"when" * Exp / mark"when",

		Assign = sym"=" * (Ct(With + If + Switch) + Ct(TableBlock + ExpListLow)) / mark"assign",
		Update = ((sym"..=" + sym"+=" + sym"-=" + sym"*=" + sym"/=" + sym"%=" + sym"or=" + sym"and=") / trim) * Exp / mark"update",

		CharOperators = Space * C(S"+-*/%^><"),
		WordOperators = op"or" + op"and" + op"<=" + op">=" + op"~=" + op"!=" + op"==" + op"..",
		BinaryOperator = (WordOperators + CharOperators) * SpaceBreak^0,

		Assignable = Cmt(DotChain + Chain, check_assignable) + Name + SelfName,
		Exp = Ct(Value * (BinaryOperator * Value)^0) / flatten_or_mark"exp",

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

		Callable = pos(Name / mark"ref") + SelfName + VarArg + Parens / mark"parens",
		Parens = sym"(" * SpaceBreak^0 * Exp * SpaceBreak^0 * sym")",

		FnArgs = symx"(" * SpaceBreak^0 * Ct(ExpList^-1) * SpaceBreak^0 * sym")" + sym"!" * -P"=" * Ct"",

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

		ClassDecl = key"class" * -P":" * (Assignable + Cc(nil)) * (key"extends" * PreventIndent * ensure(Exp, PopIndent) + C"")^-1 * (ClassBlock + Ct("")) / mark"class",

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

		KeyValue = (sym":" * -SomeSpace *  Name * lpeg.Cp()) / self_assign + Ct((KeyName + sym"[" * Exp * sym"]" + DoubleString + SingleString) * symx":" * (Exp + TableBlock + SpaceBreak^1 * Exp)),
		KeyValueList = KeyValue * (sym"," * KeyValue)^0,
		KeyValueLine = CheckIndent * KeyValueList * sym","^-1,

		FnArgsDef = sym"(" * Ct(FnArgDefList^-1) *
			(key"using" * Ct(NameList + Space * "nil") + Ct"") *
			sym")" + Ct"" * Ct"",

		FnArgDefList = FnArgDef * (sym"," * FnArgDef)^0 * (sym"," * Ct(VarArg))^0 + Ct(VarArg),
		FnArgDef = Ct((Name + SelfName) * (sym"=" * Exp)^-1),

		FunLit = FnArgsDef *
			(sym"->" * Cc"slim" + sym"=>" * Cc"fat") *
			(Body + Ct"") / mark"fndef",

		NameList = Name * (sym"," * Name)^0,
		NameOrDestructure = Name + TableLit,
		AssignableNameList = NameOrDestructure * (sym"," * NameOrDestructure)^0,

		ExpList = Exp * (sym"," * Exp)^0,
		ExpListLow = Exp * ((sym"," + sym";") * Exp)^0,

		InvokeArgs = -P"-" * (ExpList * (sym"," * (TableBlock + SpaceBreak * Advance * ArgBlock * TableBlock^-1) + TableBlock)^-1 + TableBlock),
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
			local parse_args = {...}

			local pass, err = xpcall(function()
				tree = self._g:match(str, unpack(parse_args))
			end, function(err)
				return debug.traceback(err, 2)
			end)

			-- regular error, let it bubble up
			if type(err) == "string" then
				return nil, err
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

return {
	extract_line = extract_line,

	-- parse a string
	-- returns tree, or nil and error message
	string = function (str)
		local g = build_grammar()
		return g:match(str)
	end
}

