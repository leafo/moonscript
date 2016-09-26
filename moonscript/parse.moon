debug_grammar = false
lpeg = require "lpeg"

lpeg.setmaxstack 10000 -- whoa

err_msg = "Failed to parse:%s\n [%d] >>    %s"

import Stack from require "moonscript.data"
import trim, pos_to_line, get_line from require "moonscript.util"
import unpack from require "moonscript.util"
import wrap_env from require "moonscript.parse.env"

{
  :R, :S, :V, :P, :C, :Ct, :Cmt, :Cg, :Cb, :Cc
} = lpeg

{
  :White, :Break, :Stop, :Comment, :Space, :SomeSpace, :SpaceBreak, :EmptyLine,
  :AlphaNum, :Num, :Shebang, :L
  Name: _Name
} = require "moonscript.parse.literals"

SpaceName = Space * _Name
Num = Space * (Num / (v) -> {"number", v})

{
  :Indent, :Cut, :ensure, :extract_line, :mark, :pos, :flatten_or_mark,
  :is_assignable, :check_assignable, :format_assign, :format_single_assign,
  :sym, :symx, :simple_string, :wrap_func_arg, :join_chain,
  :wrap_decorator, :check_lua_string, :self_assign, :got

} = require "moonscript.parse.util"


build_grammar = wrap_env debug_grammar, (root) ->
  _indent = Stack 0
  _do_stack = Stack 0

  state = {
    -- last pos we saw, used to report error location
    last_pos: 0
  }

  check_indent = (str, pos, indent) ->
    state.last_pos = pos
    _indent\top! == indent

  advance_indent = (str, pos, indent) ->
    top = _indent\top!
    if top != -1 and indent > top
      _indent\push indent
      true

  push_indent = (str, pos, indent) ->
    _indent\push indent
    true

  pop_indent = ->
    assert _indent\pop!, "unexpected outdent"
    true

  check_do = (str, pos, do_node) ->
    top = _do_stack\top!
    if top == nil or top
      return true, do_node
    false

  disable_do = ->
    _do_stack\push false
    true

  pop_do = ->
    assert _do_stack\pop! != nil, "unexpected do pop"
    true

  DisableDo = Cmt "", disable_do
  PopDo = Cmt "", pop_do

  keywords = {}
  key = (chars) ->
    keywords[chars] = true
    Space * chars * -AlphaNum

  op = (chars) ->
    patt = Space * C chars
    -- it's a word, treat like keyword
    if chars\match "^%w*$"
      keywords[chars] = true
      patt *= -AlphaNum

    patt

  Name = Cmt(SpaceName, (str, pos, name) ->
    return false if keywords[name]
    true
  ) / trim

  SelfName = Space * "@" * (
    "@" * (_Name / mark"self_class" + Cc"self.__class") +
    _Name / mark"self" +
    Cc"self" -- @ by itself
  )

  KeyName = SelfName + Space * _Name / mark"key_literal"
  VarArg = Space * P"..." / trim

  g = P {
    root or File
    File: Shebang^-1 * (Block + Ct"")
    Block: Ct(Line * (Break^1 * Line)^0)
    CheckIndent: Cmt(Indent, check_indent), -- validates line is in correct indent
    Line: (CheckIndent * Statement + Space * L(Stop))

    Statement: pos(
        Import + While + With + For + ForEach + Switch + Return +
        Local + Export + BreakLoop +
        Ct(ExpList) * (Update + Assign)^-1 / format_assign
      ) * Space * ((
        -- statement decorators
        key"if" * Exp * (key"else" * Exp)^-1 * Space / mark"if" +
        key"unless" * Exp / mark"unless" +
        CompInner / mark"comprehension"
      ) * Space)^-1 / wrap_decorator

    Body: Space^-1 * Break * EmptyLine^0 * InBlock + Ct(Statement) -- either a statement, or an indented block

    Advance: L Cmt(Indent, advance_indent) -- Advances the indent, gives back whitespace for CheckIndent
    PushIndent: Cmt(Indent, push_indent)
    PreventIndent: Cmt(Cc(-1), push_indent)
    PopIndent: Cmt("", pop_indent)
    InBlock: Advance * Block * PopIndent

    Local: key"local" * ((op"*" + op"^") / mark"declare_glob" + Ct(NameList) / mark"declare_with_shadows")

    Import: key"import" * Ct(ImportNameList) * SpaceBreak^0 * key"from" * Exp / mark"import"
    ImportName: (sym"\\" * Ct(Cc"colon" * Name) + Name)
    ImportNameList: SpaceBreak^0 * ImportName * ((SpaceBreak^1 + sym"," * SpaceBreak^0) * ImportName)^0

    BreakLoop: Ct(key"break"/trim) + Ct(key"continue"/trim)

    Return: key"return" * (ExpListLow/mark"explist" + C"") / mark"return"

    WithExp: Ct(ExpList) * Assign^-1 / format_assign
    With: key"with" * DisableDo * ensure(WithExp, PopDo) * key"do"^-1 * Body / mark"with"

    Switch: key"switch" * DisableDo * ensure(Exp, PopDo) * key"do"^-1 * Space^-1 * Break * SwitchBlock / mark"switch"

    SwitchBlock: EmptyLine^0 * Advance * Ct(SwitchCase * (Break^1 * SwitchCase)^0 * (Break^1 * SwitchElse)^-1) * PopIndent
    SwitchCase: key"when" * Ct(ExpList) * key"then"^-1 * Body / mark"case"
    SwitchElse: key"else" * Body / mark"else"

    IfCond: Exp * Assign^-1 / format_single_assign

    IfElse: (Break * EmptyLine^0 * CheckIndent)^-1  * key"else" * Body / mark"else"
    IfElseIf: (Break * EmptyLine^0 * CheckIndent)^-1 * key"elseif" * pos(IfCond) * key"then"^-1 * Body / mark"elseif"

    If: key"if" * IfCond * key"then"^-1 * Body * IfElseIf^0 * IfElse^-1 / mark"if"
    Unless: key"unless" * IfCond * key"then"^-1 * Body * IfElseIf^0 * IfElse^-1 / mark"unless"

    While: key"while" * DisableDo * ensure(Exp, PopDo) * key"do"^-1 * Body / mark"while"

    For: key"for" * DisableDo * ensure(Name * sym"=" * Ct(Exp * sym"," * Exp * (sym"," * Exp)^-1), PopDo) *
      key"do"^-1 * Body / mark"for"

    ForEach: key"for" * Ct(AssignableNameList) * key"in" * DisableDo * ensure(Ct(sym"*" * Exp / mark"unpack" + ExpList), PopDo) * key"do"^-1 * Body / mark"foreach"

    Do: key"do" * Body / mark"do"

    Comprehension: sym"[" * Exp * CompInner * sym"]" / mark"comprehension"

    TblComprehension: sym"{" * Ct(Exp * (sym"," * Exp)^-1) * CompInner * sym"}" / mark"tblcomprehension"

    CompInner: Ct((CompForEach + CompFor) * CompClause^0)
    CompForEach: key"for" * Ct(AssignableNameList) * key"in" * (sym"*" * Exp / mark"unpack" + Exp) / mark"foreach"
    CompFor: key "for" * Name * sym"=" * Ct(Exp * sym"," * Exp * (sym"," * Exp)^-1) / mark"for"
    CompClause: CompFor + CompForEach + key"when" * Exp / mark"when"

    Assign: sym"=" * (Ct(With + If + Switch) + Ct(TableBlock + ExpListLow)) / mark"assign"
    Update: ((sym"..=" + sym"+=" + sym"-=" + sym"*=" + sym"/=" + sym"%=" + sym"or=" + sym"and=" + sym"&=" + sym"|=" + sym">>=" + sym"<<=") / trim) * Exp / mark"update"

    CharOperators: Space * C(S"+-*/%^><|&")
    WordOperators: op"or" + op"and" + op"<=" + op">=" + op"~=" + op"!=" + op"==" + op".." + op"<<" + op">>" + op"//"
    BinaryOperator: (WordOperators + CharOperators) * SpaceBreak^0

    Assignable: Cmt(Chain, check_assignable) + Name + SelfName
    Exp: Ct(Value * (BinaryOperator * Value)^0) / flatten_or_mark"exp"

    SimpleValue:
      If + Unless +
      Switch +
      With +
      ClassDecl +
      ForEach + For + While +
      Cmt(Do, check_do) +
      sym"-" * -SomeSpace * Exp / mark"minus" +
      sym"#" * Exp / mark"length" +
      sym"~" * Exp / mark"bitnot" +
      key"not" * Exp / mark"not" +
      TblComprehension +
      TableLit +
      Comprehension +
      FunLit +
      Num

    -- a function call or an object access
    ChainValue: (Chain + Callable) * Ct(InvokeArgs^-1) / join_chain

    Value: pos(
      SimpleValue +
      Ct(KeyValueList) / mark"table" +
      ChainValue +
      String)

    SliceValue: Exp

    String: Space * DoubleString + Space * SingleString + LuaString
    SingleString: simple_string("'")
    DoubleString: simple_string('"', true)

    LuaString: Cg(LuaStringOpen, "string_open") * Cb"string_open" * Break^-1 *
      C((1 - Cmt(C(LuaStringClose) * Cb"string_open", check_lua_string))^0) *
      LuaStringClose / mark"string"

    LuaStringOpen: sym"[" * P"="^0 * "[" / trim
    LuaStringClose: "]" * P"="^0 * "]"

    Callable: pos(Name / mark"ref") + SelfName + VarArg + Parens / mark"parens"
    Parens: sym"(" * SpaceBreak^0 * Exp * SpaceBreak^0 * sym")"

    FnArgs: symx"(" * SpaceBreak^0 * Ct(FnArgsExpList^-1) * SpaceBreak^0 * sym")" + sym"!" * -P"=" * Ct""
    FnArgsExpList: Exp * ((Break + sym",") * White * Exp)^0

    Chain: (Callable + String + -S".\\") * ChainItems / mark"chain" +
      Space * (DotChainItem * ChainItems^-1 + ColonChain) / mark"chain"

    ChainItems: ChainItem^1 * ColonChain^-1 + ColonChain

    ChainItem:
      Invoke +
      DotChainItem +
      Slice +
      symx"[" * Exp/mark"index" * sym"]"

    DotChainItem: symx"." * _Name/mark"dot"
    ColonChainItem: symx"\\" * _Name / mark"colon"
    ColonChain: ColonChainItem * (Invoke * ChainItems^-1)^-1

    Slice: symx"[" * (SliceValue + Cc(1)) * sym"," * (SliceValue + Cc"")  *
      (sym"," * SliceValue)^-1 *sym"]" / mark"slice"

    Invoke: FnArgs / mark"call" +
      SingleString / wrap_func_arg +
      DoubleString / wrap_func_arg +
      L(P"[") * LuaString / wrap_func_arg

    TableValue: KeyValue + Ct(Exp)

    TableLit: sym"{" * Ct(
        TableValueList^-1 * sym","^-1 *
        (SpaceBreak * TableLitLine * (sym","^-1 * SpaceBreak * TableLitLine)^0 * sym","^-1)^-1
      ) * White * sym"}" / mark"table"

    TableValueList: TableValue * (sym"," * TableValue)^0
    TableLitLine: PushIndent * ((TableValueList * PopIndent) + (PopIndent * Cut)) + Space

    -- the unbounded table
    TableBlockInner: Ct(KeyValueLine * (SpaceBreak^1 * KeyValueLine)^0)
    TableBlock: SpaceBreak^1 * Advance * ensure(TableBlockInner, PopIndent) / mark"table"

    ClassDecl: key"class" * -P":" * (Assignable + Cc(nil)) * (key"extends" * PreventIndent * ensure(Exp, PopIndent) + C"")^-1 * (ClassBlock + Ct("")) / mark"class"

    ClassBlock: SpaceBreak^1 * Advance *
      Ct(ClassLine * (SpaceBreak^1 * ClassLine)^0) * PopIndent
    ClassLine: CheckIndent * ((
        KeyValueList / mark"props" +
        Statement / mark"stm" +
        Exp / mark"stm"
      ) * sym","^-1)

    Export: key"export" * (
      Cc"class" * ClassDecl +
      op"*" + op"^" +
      Ct(NameList) * (sym"=" * Ct(ExpListLow))^-1) / mark"export"

    KeyValue: (sym":" * -SomeSpace *  Name * lpeg.Cp!) / self_assign +
      Ct(
        (KeyName + sym"[" * Exp * sym"]" +Space * DoubleString + Space * SingleString) *
        symx":" *
        (Exp + TableBlock + SpaceBreak^1 * Exp)
      )

    KeyValueList: KeyValue * (sym"," * KeyValue)^0
    KeyValueLine: CheckIndent * KeyValueList * sym","^-1

    FnArgsDef: sym"(" * White * Ct(FnArgDefList^-1) *
      (key"using" * Ct(NameList + Space * "nil") + Ct"") *
      White * sym")" + Ct"" * Ct""

    FnArgDefList: FnArgDef * ((sym"," + Break) * White * FnArgDef)^0 * ((sym"," + Break) * White * Ct(VarArg))^0 + Ct(VarArg)
    FnArgDef: Ct((Name + SelfName) * (sym"=" * Exp)^-1)

    FunLit: FnArgsDef *
      (sym"->" * Cc"slim" + sym"=>" * Cc"fat") *
      (Body + Ct"") / mark"fndef"

    NameList: Name * (sym"," * Name)^0
    NameOrDestructure: Name + TableLit
    AssignableNameList: NameOrDestructure * (sym"," * NameOrDestructure)^0

    ExpList: Exp * (sym"," * Exp)^0
    ExpListLow: Exp * ((sym"," + sym";") * Exp)^0

    -- open args
    InvokeArgs: -P"-" * (ExpList * (sym"," * (TableBlock + SpaceBreak * Advance * ArgBlock * TableBlock^-1) + TableBlock)^-1 + TableBlock)
    ArgBlock: ArgLine * (sym"," * SpaceBreak * ArgLine)^0 * PopIndent
    ArgLine: CheckIndent * ExpList
  }

  g, state

file_parser = ->
  g, state = build_grammar!
  file_grammar = White * g * White * -1

  {
    match: (str) =>
      local tree
      _, err = xpcall (->
        tree = file_grammar\match str
      ), (err) ->
        debug.traceback err, 2

      -- regular error, let it bubble up
      if type(err) == "string"
        return nil, err

      unless tree
        local msg
        err_pos = state.last_pos

        if err
          node, msg = unpack err
          msg = " " .. msg if msg
          err_pos = node[-1]

        line_no = pos_to_line str, err_pos
        line_str = get_line(str, line_no) or ""
        return nil, err_msg\format msg or "", line_no, trim line_str

      tree
  }

{
  :extract_line
  :build_grammar

  -- parse a string as a file
  -- returns tree, or nil and error message
  string: (str) -> file_parser!\match str
}

