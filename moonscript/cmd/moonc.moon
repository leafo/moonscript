-- assorted utilities for moonc command line tool

lfs = require "lfs"

import split from require "moonscript.util"

local *

dirsep = package.config\sub 1,1
dirsep_chars = if dirsep == "\\"
  "\\/" -- windows
else
  dirsep

-- similar to mkdir -p
mkdir = (path) ->
  chunks = split path, dirsep

  local accum
  for dir in *chunks
    accum = accum and "#{accum}#{dirsep}#{dir}" or dir
    lfs.mkdir accum

  lfs.attributes path, "mode"

-- strips excess / and ensures path ends with /
normalize_dir = (path) ->
  path\match("^(.-)[#{dirsep_chars}]*$") .. dirsep

-- parse the directory out of a path
parse_dir = (path) ->
  (path\match "^(.-)[^#{dirsep_chars}]*$")

-- parse the filename out of a path
parse_file = (path) ->
  (path\match "^.-([^#{dirsep_chars}]*)$")

-- converts .moon to a .lua path for calcuating compile target
convert_path = (path) ->
  new_path = path\gsub "%.moon$", ".lua"
  if new_path == path
    new_path = path .. ".lua"
  new_path

format_time = (time) ->
  "%.3fms"\format time*1000

gettime = do
  local socket
  ->
    if socket == nil
      pcall ->
        socket = require "socket"

      unless socket
        socket = false

    if socket
      socket.gettime()
    else
      nil, "LuaSocket needed for benchmark"


import pos_to_line from require "moonscript.util"

reverse_line_number = (code, line_table, line_num) ->
  for i = line_num,0,-1
    if line_table[i]
      return pos_to_line code, line_table[i]
  "unknown"

-- compiles file to lua, returns lua code
-- returns nil, error on error
-- returns true if some option handled the output instead
compile_file_text = (text, opts={}) ->
  parse = require "moonscript.parse"
  compile = require "moonscript.compile"

  parse_time = if opts.benchmark
    assert gettime!

  tree, err = parse.string text
  return nil, err unless tree

  if parse_time
    parse_time = gettime! - parse_time

  if opts.show_parse_tree
    dump = require "moonscript.dump"
    dump.tree tree
    return true

  compile_time = if opts.benchmark
    gettime!

  code, posmap_or_err, err_pos = compile.tree tree

  unless code
    return nil, compile.format_error posmap_or_err, err_pos, text

  if compile_time
    compile_time = gettime() - compile_time

  if opts.show_posmap
    import debug_posmap from require "moonscript.util"
    print "Pos", "Lua", ">>", "Moon"
    print debug_posmap posmap_or_err, text, code
    return true

  if opts.benchmark
    print table.concat {
      opts.fname or "stdin",
      "Parse time  \t" .. format_time(parse_time),
      "Compile time\t" .. format_time(compile_time),
      ""
    }, "\n"
    return true

  if opts.keep_line_number
    line_map = {}  -- lua line to moon line
    for lua_line_number,moon_pos in pairs(posmap_or_err)
      line_map[lua_line_number] = reverse_line_number text, posmap_or_err, lua_line_number
    aligned_code = ""
    lua_line_number = 1
    current_moon_line_number = 1
    for line in string.gmatch(code..'\n', "(.-)\n")
      if moon_line_number = line_map[lua_line_number]
        to_next_line = false
        while current_moon_line_number < moon_line_number
          to_next_line = true
          aligned_code ..= '\n'
          current_moon_line_number += 1
        unless to_next_line
          aligned_code ..= ' '  -- add a space
      else
        aligned_code ..= ' '
        -- BUG cannot tell whether it is part of multi-line string
        -- there should be \n only if it is a multi-line string
      aligned_code ..= line
      lua_line_number += 1
    code = aligned_code .. '\n'

  code

write_file = (fname, code) ->
  mkdir parse_dir fname
  f, err = io.open fname, "w"
  unless f
    return nil, err

  assert f\write code
  assert f\write "\n"
  f\close!
  "build"

compile_and_write = (src, dest, opts={}) ->
  f = io.open src
  unless f
    return nil, "Can't find file"

  text = assert f\read("*a")
  f\close!

  code, err = compile_file_text text, opts

  if not code
    return nil, err

  if code == true
    return true

  if opts.print
    print code
    return true

  write_file dest, code

is_abs_path = (path) ->
  first = path\sub 1, 1
  if dirsep == "\\"
    first == "/" or first == "\\" or path\sub(2,1) == ":"
  else
    first == dirsep


-- calcuate where a path should be compiled to
-- target_dir: the directory to place the file (optional, from -t flag)
-- base_dir: the directory where the file came from when globbing recursively
path_to_target = (path, target_dir=nil, base_dir=nil) ->
  target = convert_path path

  if target_dir
    target_dir = normalize_dir target_dir

  if base_dir and target_dir
    -- one directory back
    head = base_dir\match("^(.-)[^#{dirsep_chars}]*[#{dirsep_chars}]?$")

    if head
      start, stop = target\find head, 1, true
      if start == 1
        target = target\sub(stop + 1)

  if target_dir
    if is_abs_path target
      target = parse_file target

    target = target_dir .. target

  target

{
  :dirsep
  :mkdir
  :normalize_dir
  :parse_dir
  :parse_file
  :convert_path
  :gettime
  :format_time
  :path_to_target

  :compile_file_text
  :compile_and_write
}
