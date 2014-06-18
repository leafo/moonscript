
util = require "moonscript.util"

lpeg = require "lpeg"

import concat, insert from table
import split, pos_to_line from util

user_error = (...) ->
  error {"user-error", ...}

-- find the line number of `pos` chars into fname
lookup_line = (fname, pos, cache) ->
  if not cache[fname]
    with assert io.open(fname)
      cache[fname] = \read "*a"
      \close!
  pos_to_line cache[fname], pos

-- reverse the line number in fname using line_table
reverse_line_number = (fname, line_table, line_num, cache) ->
  for i = line_num,0,-1
    if line_table[i]
      return lookup_line fname, line_table[i], cache
  "unknown"


-- strip traceback lines up to chunk func
-- replace reference to chunk_func with "main chunk"
truncate_traceback = (traceback, chunk_func="moonscript_chunk") ->
  traceback = split traceback, "\n"
  stop = #traceback
  while stop > 1
    break if traceback[stop]\match chunk_func
    stop -= 1

  traceback = [t for t in *traceback[1,stop]]

  rep = "function '" .. chunk_func .. "'"
  traceback[#traceback] = traceback[#traceback]\gsub rep, "main chunk"

  concat traceback, "\n"

rewrite_traceback = (text, err) ->
  line_tables = require "moonscript.line_tables"
  import V, S, Ct, C from lpeg
  header_text = "stack traceback:"

  Header, Line = V("Header"), V("Line")
  Break = lpeg.S "\n"
  g = lpeg.P {
    Header
    Header: header_text * Break * Ct(Line^1)
    Line: "\t" * C((1 - Break)^0) * (Break + -1)
  }

  cache = {} -- loaded file cache
  rewrite_single = (trace) ->
    fname, line, msg = trace\match '^(.-):(%d+): (.*)$'
    tbl = line_tables["@#{fname}"]
    if fname and tbl
      concat {
        fname, ":"
        reverse_line_number(fname, tbl, line, cache)
        ": "
        "(", line, ") "
        msg
      }
    else
      trace

  err = rewrite_single err
  match = g\match text

  return nil unless match

  for i, trace in ipairs match
    match[i] = rewrite_single trace

  concat {
    "moon: " .. err
    header_text
    "\t" .. concat match, "\n\t"
  }, "\n"


{ :rewrite_traceback, :truncate_traceback, :user_error, :reverse_line_number }

