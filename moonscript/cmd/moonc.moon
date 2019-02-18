-- assorted utilities for moonc command line tool

lfs = require "lfs"

import split from require "moonscript.util"
import dirsep, normalize_dir, normalize_path, parse_dir, parse_file, parse_subtree, convert_path from require "moonscript.cmd.path_handling"

local *

main = (cli_args) ->
  argparse = require "argparse"
  parser = with argparse("moonc", "The Moonscript compiler.")
    \flag("-l --lint", "Perform a lint on the file instead of compiling.")
    \flag("-v --version", "Print version.")
    \flag("-w --watch", "Watch file/directory for updates.")
    \option("--transform", "Transform syntax tree with module.")
    \mutex(
      \option("-t --output-to", "Specify where to place compiled files."),
      \option("-o", "Write output to file."),
      \flag("-p", "Write output to standard output."),
      \flag("-T", "Write parse tree instead of code (to stdout)."),
      \flag("-b", "Write parse and compile time instead of code(to stdout)."),
      \flag("-X", "Write line rewrite map instead of code (to stdout).")
    )
    \flag("-",
      "Read from standard in, print to standard out (Must be only argument).")
  read_stdin = cli_args[1] == "--" -- luacheck: ignore 113
  unless read_stdin
    parser\argument("file/directory")\args("+")

  opts = parser\parse cli_args

  if opts.version
    v = require "moonscript.version"
    v.print_version!
    os.exit!

  if read_stdin
    process_stdin_and_exit!

  inputs = opts["file/directory"]
  if inputs == nil
    error "No paths specified"

  if opts.o
    if #inputs > 1
      error "-o can only be used with a single input"
    elseif (lfs.attributes inputs[1], "mode") == "directory"
      error "-o can only be used with a file input, not a directory"

  -- Determine if the CLI paths are valid, and handle --output-to and exclusive
  -- vs. inclusive directories
  output_to, cli_paths, prefix_map = parse_cli_paths inputs, opts.output_to

  -- Handle file-watching, linting, and compilation
  if opts.watch
    handle_watch_loop opts, output_to, cli_paths, prefix_map
  else
    -- Scan CLI argument files/directories to get full set of files to build from
    files = scan_initial_files output_to, cli_paths, prefix_map
    if opts.lint
      lint_for files
    else
      compile_for opts, files

process_stdin_and_exit = () ->
  parse = require "moonscript.parse"
  compile = require "moonscript.compile"

  text = io.stdin\read "*a"
  tree, err = parse.string text

  unless tree
    error err
  code, err, pos = compile.tree tree

  unless code
    error(compile.format_error err, pos, text)

  print code
  os.exit!

parse_cli_paths = (input_paths, output_to=false) ->
  unless input_paths
    error "No paths specified"
  if output_to
    output_to = normalize_dir output_to
  cli_paths = {}
  -- Contains a map of given directories to their corresponding output
  -- directory. The two will be equal if @output_to is not set.
  prefix_map = {}
  for path in *input_paths
    mode, err_msg, err_code = lfs.attributes(path, 'mode')
    switch mode
      when 'file'
        table.insert cli_paths, {(normalize_path path), 'file'}
      when 'directory'
        add_prefix_for_dir output_to, prefix_map, path
        table.insert cli_paths, {(normalize_dir path), 'directory'}
      when nil
        error "Error code #{err_code} accessing given path `#{path}`, error message: #{err_msg}"
      else
        error "Given path `#{path}` has unexpected filesystem mode `#{mode}`"
  return output_to, cli_paths, prefix_map

handle_watch_loop = (opts, output_to, input_paths, prefix_map) ->
  log_msg = (...) ->
    unless opts.p
      io.stderr\write(table.concat({...}, " ") .. "\n")

  remove_orphaned_output = (target, path_type) ->
    if path_type == "directory"
      is_ok, err_string, err_no = lfs.rmdir target
      -- rmdir() can legitimately fail if the dir being removed is non-empty
      -- (e.g. if there is a vendored Lua file in here), TODO look up the Linux
      -- and Windows error codes for 'directory not empty' and silently fail on
      -- those, loudly fail on other error types?
      if is_ok
        log_msg "Removed output directory", target
      else
        log_msg "Error removing directory", target, "err_no", err_no, "msg", err_string
    elseif path_type == "file"
      is_ok, err_string = os.remove target
      if is_ok
        log_msg "Removed output file", target
      else
        log_msg "Error removing file", target, err_string

  watcher = create_watcher input_paths

  for filename in watcher
    target = output_for(output_to, prefix_map, filename, "file")

    if opts.o
      target = opts.o

    if opts.lint
      lint = require "moonscript.cmd.lint"
      success, err = lint.lint_file filename
      if success
        io.stderr\write success .. "\n\n"
      elseif err
        io.stderr\write filename .. "\n" .. err .. "\n\n"
    else
      success, err = compile_and_write filename, target
      if not success
        io.stderr\write table.concat({
          "",
          "Error: " .. filename,
          err,
          "\n",
        }, "\n")
      elseif success == "build"
        log_msg "Built", filename, "->", target

  io.stderr\write "\nQuitting...\n"

create_watcher = (input_paths) ->
  watchers = require "moonscript.cmd.watchers"

  -- TODO cli argument to force sleep watcher (as it is potentially a little
  -- more reliable)
  watcher = if watchers.InotifyWatcher\available!
    watchers.InotifyWatcher input_paths
  else
    watchers.SleepWatcher input_paths

  return watcher\each_update!


scan_initial_files = (output_to, input_paths, prefix_map) ->
  files = {}

  for path_tuple in *input_paths
    {path, path_type} = path_tuple
    if path_type == "directory"
      -- Recursively scan directories and add .moon files in them
      process_filesystem_tree(path, nil, (file_path) ->
        if file_path\match("%.moon$")
          table.insert(files, {
            file_path, output_for(output_to, prefix_map, file_path, 'file')
          })
      )
    else
      -- Add any file paths directly given on the CLI, even if they do not end
      -- in .moon
      table.insert(files, {
        path, output_for(output_to, prefix_map, path, 'file')
      })
  return files

lint_for = (files) ->
  local has_linted_with_error
  lint = require "moonscript.cmd.lint"

  for tuple in *files
    {filename, _target} = tuple
    res, err = lint.lint_file filename
    if res
      has_linted_with_error = true
      io.stderr\write res .. "\n\n"
    elseif err
      has_linted_with_error = true
      io.stderr\write filename .. "\n" .. err.. "\n\n"

  if has_linted_with_error
    os.exit 1

compile_for = (opts, files) ->
  for tuple in *files do
    {filename, target} = tuple
    if opts.o
      target = opts.o

    success, err = compile_and_write filename, target,
      print: opts.p
      filename: filename
      benchmark: opts.b
      show_posmap: opts.X
      show_parse_tree: opts.T
      transform_module: opts.transform

    unless success
      io.stderr\write filename .. "\t" .. err .. "\n"
      os.exit 1

-- similar to mkdir -p
mkdir = (path) ->
  chunks = split path, dirsep

  local accum
  for dir in *chunks
    accum = accum and "#{accum}#{dirsep}#{dir}" or dir
    lfs.mkdir accum

  lfs.attributes path, "mode"

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
    print dump.tree tree
    return true

  compile_time = if opts.benchmark
    gettime!

  if mod = opts.transform_module
    file = assert loadfile mod
    fn = assert file!
    tree = assert fn tree

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
      opts.filename or "stdin",
      "Parse time  \t" .. format_time(parse_time),
      "Compile time\t" .. format_time(compile_time),
      ""
    }, "\n"
    return true

  code

write_file = (filename, code) ->
  mkdir parse_dir filename
  f, err = io.open filename, "w"
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

-- - If output_to isn't given... then the output path is the same as the
--   input, except .moon -> .lua
-- - If output_to is given, and the path is relative and inclusive, like
--   "src", then the transform is like "src/foo.moon" ->
--   "output_to/src/foo.lua"
-- - If output_to is given, and the path is relative and exclusive, like
--   "src/", then the transform is "src/foo.moon" -> "output_to/foo.lua"
-- - If output_to is given, and the path is absolute: the output path is the
--   same as if it were relative, just relocated under output_to as if that
--   were /
add_prefix_for_dir = (output_to, prefix_map, directory) ->
  last = directory\sub #directory, #directory
  is_exclusive = if dirsep == "\\"
    last == "/" or last == "\\"
  else
    last == dirsep

  directory = normalize_dir directory
  if prefix_start = output_to
    if is_exclusive
      prefix_map[directory] = prefix_start .. parse_subtree directory
    else
      prefix_map[directory] = prefix_start .. directory
  else
    prefix_map[directory] = directory

-- Returns the corresponding .lua output for a given .moon path
output_for = (output_to, prefix_map, path, path_type) ->
  unless path_type == "directory"
    path = convert_path path
  -- Handle inclusive and exclusive directories
  for prefix_path, prefix_output in pairs prefix_map
    if #path < #prefix_path
      continue

    -- The given path is a child of one of the prefix directories
    if path\sub(1, #prefix_path) == prefix_path
      output_path = prefix_output .. path\sub(#prefix_path + 1, #path)
      return output_path
  -- Otherwise just apply output_to if set
  if output_to
    path = output_to .. path
  return path

process_filesystem_tree = (root, directory_callback, file_callback) ->
  root = normalize_dir root
  directory_callback root if directory_callback
  ok, _iter, dirobj = pcall(lfs.dir, root)
  return unless ok
  while true
    filename = dirobj\next!
    break unless filename
    unless filename\match("^%.")
      fpath = root .. filename
      mode = lfs.attributes(fpath, "mode")
      switch mode
        when "directory"
          fpath = fpath .. '/'
          process_filesystem_tree fpath, directory_callback, file_callback
        when "file"
          file_callback fpath if file_callback
        when nil
          nil -- TODO? log path ceasing to exist between dir() and attributes()?
        else
          error "Unexpected filetype #{mode}"

{
  :main

  :mkdir
  :gettime
  :format_time

  :compile_file_text
  :compile_and_write
  :process_filesystem_tree

  :parse_cli_paths
  :output_for
}
