local util = require("moonscript.util")
local lpeg = require("lpeg")
local concat, insert = table.concat, table.insert
local split, pos_to_line = util.split, util.pos_to_line
local user_error
user_error = function(...)
  return error({
    "user-error",
    ...
  })
end
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
local truncate_traceback
truncate_traceback = function(traceback, chunk_func)
  if chunk_func == nil then
    chunk_func = "moonscript_chunk"
  end
  traceback = split(traceback, "\n")
  local stop = #traceback
  while stop > 1 do
    if traceback[stop]:match(chunk_func) then
      break
    end
    stop = stop - 1
  end
  traceback = (function()
    local _accum_0 = { }
    local _len_0 = 1
    local _list_0 = traceback
    local _max_0 = stop
    for _index_0 = 1, _max_0 < 0 and #_list_0 + _max_0 or _max_0 do
      local t = _list_0[_index_0]
      _accum_0[_len_0] = t
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)()
  local rep = "function '" .. chunk_func .. "'"
  traceback[#traceback] = traceback[#traceback]:gsub(rep, "main chunk")
  return concat(traceback, "\n")
end
local rewrite_traceback
rewrite_traceback = function(text, err)
  local line_tables = require("moonscript.line_tables")
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
        "(",
        line,
        ")",
        ": ",
        msg
      })
    else
      return trace
    end
  end
  err = rewrite_single(err)
  local match = g:match(text)
  if not (match) then
    return nil
  end
  for i, trace in ipairs(match) do
    match[i] = rewrite_single(trace)
  end
  return concat({
    "moon: " .. err,
    header_text,
    "\t" .. concat(match, "\n\t")
  }, "\n")
end
return {
  rewrite_traceback = rewrite_traceback,
  truncate_traceback = truncate_traceback,
  user_error = user_error
}
