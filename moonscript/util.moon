
import concat from table

unpack = unpack or table.unpack
type = type

moon =
  is_object: (value) -> -- is a moonscript object
    type(value) == "table" and value.__class

  is_a: (thing, t) ->
    return false unless type(thing) == "table"
    cls = thing.__class
    while cls
      if cls == t
        return true
      cls = cls.__parent

    false

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

trim = (str) ->
  str\match "^%s*(.-)%s*$"

get_line = (str, line_num) ->
  -- todo: this returns an extra blank line at the end
  for line in str\gmatch "([^\n]*)\n?"
    return line if line_num == 1
    line_num -= 1

get_closest_line = (str, line_num) ->
  line = get_line str, line_num
  if (not line or trim(line) == "") and line_num > 1
    get_closest_line(str, line_num - 1)
  else
    line, line_num

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


debug_posmap = (posmap, moon_code, lua_code) ->
  tuples = [{k, v} for k, v in pairs posmap]
  table.sort tuples, (a, b) -> a[1] < b[1]

  lines = for pair in *tuples
    lua_line, pos = unpack pair
    moon_line = pos_to_line moon_code, pos

    lua_text = get_line lua_code, lua_line
    moon_text = get_closest_line moon_code, moon_line

    "#{pos}\t #{lua_line}:[ #{trim lua_text} ] >> #{moon_line}:[ #{trim moon_text} ]"

  concat(lines, "\n")

setfenv = setfenv or (fn, env) ->
  local name
  i = 1
  while true
    name = debug.getupvalue fn, i
    break if not name or name == "_ENV"
    i += 1

  if name
    debug.upvaluejoin fn, i, (-> env), 1

  fn

getfenv = getfenv or (fn) ->
  i = 1
  while true
    name, val = debug.getupvalue fn, i
    break unless name
    return val if name == "_ENV"
    i += 1
  nil

-- moves the last argument to the front if it's a table, or returns empty table
-- inserted to the front of args
get_options = (...) ->
  count = select "#", ...
  opts = select count, ...
  if type(opts) == "table"
    opts, unpack {...}, nil, count - 1
  else
    {}, ...

safe_module = (name, tbl) ->
  setmetatable tbl, {
    __index: (key) =>
      error "Attempted to import non-existent `#{key}` from #{name}"
  }

{
  :moon, :pos_to_line, :get_closest_line, :get_line, :trim, :split, :dump,
  :debug_posmap, :getfenv, :setfenv, :get_options, :unpack, :safe_module
}

