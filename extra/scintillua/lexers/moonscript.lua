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
local regex_str = l.delimited_range('/', '\\', nil, nil, '\n') * S('igm')^0
local string = token(l.STRING, sq_str + dq_str) + P(function(input, index)
  if index == 1 then return index end
  local i = index
  while input:sub(i - 1, i - 1):match('[ \t\r\n\f]') do i = i - 1 end
  return input:sub(i - 1, i - 1):match('[+%-*%%^!=&|?:;,()%[%]{}]') and index
end) * token('regex', regex_str) + token('longstring', longstring)

-- Numbers.
local number = token(l.NUMBER, l.float + l.integer)

-- Keywords.
local keyword = token(l.KEYWORD, word_match {
	'return', 'break', 'for', 'while',
	'if', 'else', 'elseif', 'then', 'export',
	'import', 'from', 'with', 'in', 'and',
	'or', 'not', 'class', 'extends', 'super', 'do',
	'true', 'false', 'nil', 'using', 'switch', 'when',
})

-- Functions.
local func = token(l.FUNCTION, word_match {
  'assert', 'collectgarbage', 'dofile', 'error', 'getfenv', 'getmetatable',
  'ipairs', 'load', 'loadfile', 'loadstring', 'module', 'next', 'pairs',
  'pcall', 'print', 'rawequal', 'rawget', 'rawset', 'require', 'setfenv',
  'setmetatable', 'tonumber', 'tostring', 'type', 'unpack', 'xpcall'
})

-- Identifiers.
local identifier = token(l.IDENTIFIER, l.word)

-- Operators.
local operator = token(l.OPERATOR, '~=' + S('+-*!\\/%^#=<>;:,.{}[]()'))

-- self ref
local self_var = token('self_ref', "@" * l.word + "self")

local proper_ident = token('proper_ident', R("AZ") * l.word)

_rules = {
  { 'whitespace', ws },
  { 'self', self_var },
  { 'keyword', keyword },
  { 'function', func },
  { 'identifier', proper_ident + identifier },
  { 'comment', comment },
  { 'number', number },
  { 'string', string },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

local pink = l.color("ED", "4E", "78")

_tokenstyles = {
  { 'regex', l.style_string..{ back = l.color('44', '44', '44')} },
  { 'longstring', l.style_string },
  { 'self_ref', { fore = l.colors.purple } },
  { 'proper_ident', { fore = pink, bold = true } },
  { l.OPERATOR, { fore = l.colors.red, bold = true } },
  { l.FUNCTION, { fore = l.colors.orange } },
}
