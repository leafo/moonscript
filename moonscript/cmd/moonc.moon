-- assorted utilities for moonc command line tool

lfs = require "lfs"

import split from require "moonscript.util"

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

-- compiles file to lua
-- returns nil, error on error
-- returns just nil if some option handled the output instead
compile_file_text = (text, fname, opts={}) ->
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
    return nil

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
    return nil

  if opts.benchmark
    print table.concat {
      fname,
      "Parse time  \t" .. format_time(parse_time),
      "Compile time\t" .. format_time(compile_time),
      ""
    }, "\n"
    return nil

  code

{
  :dirsep
  :mkdir
  :normalize_dir
  :parse_dir
  :parse_file
  :new_path
  :convert_path
  :gettime
  :format_time
  :compile_file_text
}
