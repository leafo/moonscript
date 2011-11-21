-- Copyright 2006-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Moonscript lexer by leaf corcoran <http://leafo.net>

local l = lexer
local token, word_match = l.token, l.word_match
local P, S, R = l.lpeg.P, l.lpeg.S, l.lpeg.R

module(...)

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

local longstring = #('[[' + ('[' * P('=')^0 * '['))
local longstring = longstring * P(function(input, index)
  local level = input:match('^%[(=*)%[', index)
  if level then
    local _, stop = input:find(']'..level..']', index, true)
    return stop and stop + 1 or #input + 1
  end
end)

-- Comments.
local line_comment = '--' * l.nonnewline^0
local block_comment = '--' * longstring
local comment = token(l.COMMENT, block_comment + line_comment)

-- Strings.
local sq_str = l.delimited_range("'", '\\', true)
local dq_str = l.delimited_range('"', '\\', true)
local string = token(l.STRING, sq_str + dq_str + longstring)

-- Numbers.
local number = token(l.NUMBER, l.float + l.integer)

-- Keywords.
local keyword = token(l.KEYWORD, word_match {
	'return', 'break', 'for', 'while',
	'if', 'else', 'elseif', 'then', 'export',
	'import', 'from', 'with', 'in', 'and',
	'or', 'not', 'class', 'extends', 'super', 'do',
	'using', 'switch', 'when',
})

local special = token("special", word_match { "true", "false", "nil" }) 

-- Functions.
local builtin = token(l.FUNCTION, word_match {
  'assert', 'collectgarbage', 'dofile', 'error', 'getfenv', 'getmetatable',
  'ipairs', 'load', 'loadfile', 'loadstring', 'module', 'next', 'pairs',
  'pcall', 'print', 'rawequal', 'rawget', 'rawset', 'require', 'setfenv',
  'setmetatable', 'tonumber', 'tostring', 'type', 'unpack', 'xpcall'
})

-- Identifiers.
local identifier = token(l.IDENTIFIER, l.word)

local fndef = token("fndef", P"->" + P"=>")
local err = token(l.ERROR, word_match { "function", "end" })

-- Operators.
local symbol = token("symbol", S("(){}[]"))
local operator = token(l.OPERATOR, '~=' + S('+-*!\\/%^#=<>;:,.'))

-- self ref
local self_var = token("self_ref", "@" * l.word + "self")

local proper_ident = token("proper_ident", R("AZ") * l.word)

_rules = {
  { 'whitespace', ws },
  { 'error', err },
  { 'self', self_var },
  { 'special', special },
  { 'keyword', keyword },
  { 'builtin', builtin },
  { 'identifier', proper_ident + identifier },
  { 'comment', comment },
  { 'number', number },
  { 'string', string },
  { 'fndef', fndef },
  { 'symbol', symbol },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

local style_special = { fore = l.colors.light_blue }
local style_fndef = { fore = l.colors.green }

_tokenstyles = {
  { 'self_ref', style_special },
  { 'proper_ident', l.style_class },
  { 'fndef', style_fndef },
  { 'symbol', style_fndef },
  { 'special', style_special },
  { l.OPERATOR, { fore = l.colors.red, bold = true } },
  { l.FUNCTION, { fore = l.colors.orange } },
}
