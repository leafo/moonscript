
module "moonscript.util", package.seeall

export moon
export pos_to_line, get_closest_line, get_line
export reversed, trim, split
export dump

import concat from table

moon =
  is_object: (value) -> -- is a moonscript object
    type(value) == "table" and value.__class
  type: (value) -> -- the moonscript object class
    base_type = type value
    if base_type == "table"
      cls = value.__class
      return cls if cls
    base_type

-- convet position in text to line number
pos_to_line = (str, pos) ->
  line = 1
  for _ in str\sub(1, pos)\gmatch("\n")
    line += 1
  line

get_closest_line = (str, line_num) ->
  line = get_line str, line_num
  if (not line or trim(line) == "") and line_num > 1
    get_closest_line(str, line_num - 1)
  else
    line, line_num

get_line = (str, line_num) ->
  for line in str\gmatch "(.-)[\n$]"
    return line if line_num == 1
    line_num -= 1

reversed = (seq) ->
  coroutine.wrap ->
    for i=#seq,1,-1
      coroutine.yield i, seq[i]

trim = (str) ->
  str\match "^%s*(.-)%s*$"

split = (str, delim) ->
  return {} if str == ""
  str ..= delim
  [m for m in str\gmatch("(.-)"..delim)]

dump = (what) ->
  seen = {}
  _dump = (what, depth=0) ->
    t = type what
    if t == "string"
			'"'..what..'"\n'
    elseif t == "table"
      if seen[what]
        return "recursion("..tostring(what) ..")...\n"
      seen[what] = true

      depth += 1
      lines = for k,v in pairs what
        (" ")\rep(depth*4).."["..tostring(k).."] = ".._dump(v, depth)

      seen[what] = false

      "{\n" .. concat(lines) .. (" ")\rep((depth - 1)*4) .. "}\n"
    else
      tostring(what).."\n"

  _dump what


