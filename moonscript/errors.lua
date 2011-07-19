module("moonscript.errors", package.seeall)
local moon = require("moonscript")
local util = require("moonscript.util")
require("lpeg")
local concat, insert = table.concat, table.insert
local split, pos_to_line = util.split, util.pos_to_line
local lookup_line
lookup_line = function(fname, pos, cache)
  if not cache[fname] then
    do
      local _with_0 = io.open(fname)
      cache[fname] = _with_0:read("*a")
      _with_0:close()
    end
  end
  return pos_to_line(cache[fname], pos)
end
local reverse_line_number
reverse_line_number = function(fname, line_table, line_num, cache)
  for i = line_num, 0, -1 do
    if line_table[i] then
      return lookup_line(fname, line_table[i], cache)
    end
  end
  return "unknown"
end
rewrite_traceback = function(text, err)
  local line_tables = moon.line_tables
  local V, S, Ct, C = lpeg.V, lpeg.S, lpeg.Ct, lpeg.C
  local header_text = "stack traceback:"
  local Header, Line = V("Header"), V("Line")
  local Break = lpeg.S("\n")
  local g = lpeg.P({
    Header,
    Header = header_text * Break * Ct(Line ^ 1),
    Line = "\t" * C((1 - Break) ^ 0) * (Break + -1)
  })
  local cache = { }
  local rewrite_single
  rewrite_single = function(trace)
    local fname, line, msg = trace:match('^%[string "(.-)"]:(%d+): (.*)$')
    local tbl = line_tables[fname]
    if fname and tbl then
      return concat({
        fname,
        ":",
        reverse_line_number(fname, tbl, line, cache),
        ": ",
        msg
      })
    else
      return trace
    end
  end
  err = rewrite_single(err)
  local match = g:match(text)
  for i, trace in ipairs(match) do
    match[i] = rewrite_single(trace)
  end
  return concat({
    "moon:" .. err,
    header_text,
    "\t" .. concat(match, "\n\t")
  }, "\n")
end
