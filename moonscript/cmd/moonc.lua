local lfs = require("lfs")
local split
split = require("moonscript.util").split
local dirsep, normalize_dir, normalize_path, parse_dir, parse_file, parse_subtree, convert_path
do
  local _obj_0 = require("moonscript.cmd.path_handling")
  dirsep, normalize_dir, normalize_path, parse_dir, parse_file, parse_subtree, convert_path = _obj_0.dirsep, _obj_0.normalize_dir, _obj_0.normalize_path, _obj_0.parse_dir, _obj_0.parse_file, _obj_0.parse_subtree, _obj_0.convert_path
end
local main, process_stdin_and_exit, parse_cli_paths, handle_watch_loop, create_watcher, scan_initial_files, lint_for, compile_for, mkdir, format_time, gettime, compile_file_text, write_file, compile_and_write, add_prefix_for_dir, output_for, process_filesystem_tree
main = function(cli_args)
  local argparse = require("argparse")
  local parser
  do
    local _with_0 = argparse("moonc", "The Moonscript compiler.")
    _with_0:flag("-l --lint", "Perform a lint on the file instead of compiling.")
    _with_0:flag("-v --version", "Print version.")
    _with_0:flag("-w --watch", "Watch file/directory for updates.")
    _with_0:option("--transform", "Transform syntax tree with module.")
    _with_0:mutex(_with_0:option("-t --output-to", "Specify where to place compiled files."), _with_0:option("-o", "Write output to file."), _with_0:flag("-p", "Write output to standard output."), _with_0:flag("-T", "Write parse tree instead of code (to stdout)."), _with_0:flag("-b", "Write parse and compile time instead of code(to stdout)."), _with_0:flag("-X", "Write line rewrite map instead of code (to stdout)."))
    _with_0:flag("-", "Read from standard in, print to standard out (Must be only argument).")
    parser = _with_0
  end
  local read_stdin = cli_args[1] == "--"
  if not (read_stdin) then
    parser:argument("file/directory"):args("+")
  end
  local opts = parser:parse(cli_args)
  if opts.version then
    local v = require("moonscript.version")
    v.print_version()
    os.exit()
  end
  if read_stdin then
    process_stdin_and_exit()
  end
  local inputs = opts["file/directory"]
  if inputs == nil then
    error("No paths specified")
  end
  if opts.o then
    if #inputs > 1 then
      error("-o can only be used with a single input")
    elseif (lfs.attributes(inputs[1], "mode")) == "directory" then
      error("-o can only be used with a file input, not a directory")
    end
  end
  local output_to, cli_paths, prefix_map = parse_cli_paths(inputs, opts.output_to)
  if opts.watch then
    return handle_watch_loop(opts, output_to, cli_paths, prefix_map)
  else
    local files = scan_initial_files(output_to, cli_paths, prefix_map)
    if opts.lint then
      return lint_for(files)
    else
      return compile_for(opts, files)
    end
  end
end
process_stdin_and_exit = function()
  local parse = require("moonscript.parse")
  local compile = require("moonscript.compile")
  local text = io.stdin:read("*a")
  local tree, err = parse.string(text)
  if not (tree) then
    error(err)
  end
  local code, pos
  code, err, pos = compile.tree(tree)
  if not (code) then
    error(compile.format_error(err, pos, text))
  end
  print(code)
  return os.exit()
end
parse_cli_paths = function(input_paths, output_to)
  if output_to == nil then
    output_to = false
  end
  if not (input_paths) then
    error("No paths specified")
  end
  if output_to then
    output_to = normalize_dir(output_to)
  end
  local cli_paths = { }
  local prefix_map = { }
  for _index_0 = 1, #input_paths do
    local path = input_paths[_index_0]
    local mode, err_msg, err_code = lfs.attributes(path, 'mode')
    local _exp_0 = mode
    if 'file' == _exp_0 then
      table.insert(cli_paths, {
        (normalize_path(path)),
        'file'
      })
    elseif 'directory' == _exp_0 then
      add_prefix_for_dir(output_to, prefix_map, path)
      table.insert(cli_paths, {
        (normalize_dir(path)),
        'directory'
      })
    elseif nil == _exp_0 then
      error("Error code " .. tostring(err_code) .. " accessing given path `" .. tostring(path) .. "`, error message: " .. tostring(err_msg))
    else
      error("Given path `" .. tostring(path) .. "` has unexpected filesystem mode `" .. tostring(mode) .. "`")
    end
  end
  return output_to, cli_paths, prefix_map
end
handle_watch_loop = function(opts, output_to, input_paths, prefix_map)
  local log_msg
  log_msg = function(...)
    if not (opts.p) then
      return io.stderr:write(table.concat({
        ...
      }, " ") .. "\n")
    end
  end
  local remove_orphaned_output
  remove_orphaned_output = function(target, path_type)
    if path_type == "directory" then
      local is_ok, err_string, err_no = lfs.rmdir(target)
      if is_ok then
        return log_msg("Removed output directory", target)
      else
        return log_msg("Error removing directory", target, "err_no", err_no, "msg", err_string)
      end
    elseif path_type == "file" then
      local is_ok, err_string = os.remove(target)
      if is_ok then
        return log_msg("Removed output file", target)
      else
        return log_msg("Error removing file", target, err_string)
      end
    end
  end
  local watcher = create_watcher(output_to, input_paths, prefix_map)
  for file_tuple in watcher do
    local event_type, filename, target, path_type
    event_type, filename, target, path_type = file_tuple[1], file_tuple[2], file_tuple[3], file_tuple[4]
    if opts.o then
      target = opts.o
    end
    if opts.lint then
      if event_type == "changedfile" then
        local lint = require("moonscript.cmd.lint")
        local success, err = lint.lint_file(filename)
        if success then
          io.stderr:write(success .. "\n\n")
        elseif err then
          io.stderr:write(filename .. "\n" .. err .. "\n\n")
        end
      elseif event_type == "removed" then
        remove_orphaned_output(target, path_type)
      end
    else
      if event_type == "changedfile" then
        local success, err = compile_and_write(filename, target)
        if not success then
          io.stderr:write(table.concat({
            "",
            "Error: " .. filename,
            err,
            "\n"
          }, "\n"))
        elseif success == "build" then
          log_msg("Built", filename, "->", target)
        end
      elseif event_type == "removed" then
        remove_orphaned_output(target, path_type)
      end
    end
  end
  return io.stderr:write("\nQuitting...\n")
end
create_watcher = function(output_to, input_paths, prefix_map)
  local watchers = require("moonscript.cmd.watchers")
  local watcher
  if watchers.InotifyWatcher:available() then
    watcher = watchers.InotifyWatcher(output_to, input_paths, prefix_map)
  else
    watcher = watchers.SleepWatcher(output_to, input_paths, prefix_map)
  end
  return watcher:each_update()
end
scan_initial_files = function(output_to, input_paths, prefix_map)
  local files = { }
  for _index_0 = 1, #input_paths do
    local path_tuple = input_paths[_index_0]
    local path, path_type
    path, path_type = path_tuple[1], path_tuple[2]
    if path_type == "directory" then
      process_filesystem_tree(path, nil, function(file_path)
        if file_path:match("%.moon$") then
          return table.insert(files, {
            file_path,
            output_for(output_to, prefix_map, file_path, 'file')
          })
        end
      end)
    else
      table.insert(files, {
        path,
        output_for(output_to, prefix_map, path, 'file')
      })
    end
  end
  return files
end
lint_for = function(files)
  local has_linted_with_error
  local lint = require("moonscript.cmd.lint")
  for _index_0 = 1, #files do
    local tuple = files[_index_0]
    local filename, _target
    filename, _target = tuple[1], tuple[2]
    local res, err = lint.lint_file(filename)
    if res then
      has_linted_with_error = true
      io.stderr:write(res .. "\n\n")
    elseif err then
      has_linted_with_error = true
      io.stderr:write(filename .. "\n" .. err .. "\n\n")
    end
  end
  if has_linted_with_error then
    return os.exit(1)
  end
end
compile_for = function(opts, files)
  for _index_0 = 1, #files do
    local tuple = files[_index_0]
    local filename, target
    filename, target = tuple[1], tuple[2]
    if opts.o then
      target = opts.o
    end
    local success, err = compile_and_write(filename, target, {
      print = opts.p,
      filename = filename,
      benchmark = opts.b,
      show_posmap = opts.X,
      show_parse_tree = opts.T,
      transform_module = opts.transform
    })
    if not (success) then
      io.stderr:write(filename .. "\t" .. err .. "\n")
      os.exit(1)
    end
  end
end
mkdir = function(path)
  local chunks = split(path, dirsep)
  local accum
  for _index_0 = 1, #chunks do
    local dir = chunks[_index_0]
    accum = accum and tostring(accum) .. tostring(dirsep) .. tostring(dir) or dir
    lfs.mkdir(accum)
  end
  return lfs.attributes(path, "mode")
end
format_time = function(time)
  return ("%.3fms"):format(time * 1000)
end
do
  local socket
  gettime = function()
    if socket == nil then
      pcall(function()
        socket = require("socket")
      end)
      if not (socket) then
        socket = false
      end
    end
    if socket then
      return socket.gettime()
    else
      return nil, "LuaSocket needed for benchmark"
    end
  end
end
compile_file_text = function(text, opts)
  if opts == nil then
    opts = { }
  end
  local parse = require("moonscript.parse")
  local compile = require("moonscript.compile")
  local parse_time
  if opts.benchmark then
    parse_time = assert(gettime())
  end
  local tree, err = parse.string(text)
  if not (tree) then
    return nil, err
  end
  if parse_time then
    parse_time = gettime() - parse_time
  end
  if opts.show_parse_tree then
    local dump = require("moonscript.dump")
    print(dump.tree(tree))
    return true
  end
  local compile_time
  if opts.benchmark then
    compile_time = gettime()
  end
  do
    local mod = opts.transform_module
    if mod then
      local file = assert(loadfile(mod))
      local fn = assert(file())
      tree = assert(fn(tree))
    end
  end
  local code, posmap_or_err, err_pos = compile.tree(tree)
  if not (code) then
    return nil, compile.format_error(posmap_or_err, err_pos, text)
  end
  if compile_time then
    compile_time = gettime() - compile_time
  end
  if opts.show_posmap then
    local debug_posmap
    debug_posmap = require("moonscript.util").debug_posmap
    print("Pos", "Lua", ">>", "Moon")
    print(debug_posmap(posmap_or_err, text, code))
    return true
  end
  if opts.benchmark then
    print(table.concat({
      opts.filename or "stdin",
      "Parse time  \t" .. format_time(parse_time),
      "Compile time\t" .. format_time(compile_time),
      ""
    }, "\n"))
    return true
  end
  return code
end
write_file = function(filename, code)
  mkdir(parse_dir(filename))
  local f, err = io.open(filename, "w")
  if not (f) then
    return nil, err
  end
  assert(f:write(code))
  assert(f:write("\n"))
  f:close()
  return "build"
end
compile_and_write = function(src, dest, opts)
  if opts == nil then
    opts = { }
  end
  local f = io.open(src)
  if not (f) then
    return nil, "Can't find file"
  end
  local text = assert(f:read("*a"))
  f:close()
  local code, err = compile_file_text(text, opts)
  if not code then
    return nil, err
  end
  if code == true then
    return true
  end
  if opts.print then
    print(code)
    return true
  end
  return write_file(dest, code)
end
add_prefix_for_dir = function(output_to, prefix_map, directory)
  local last = directory:sub(#directory, #directory)
  local is_exclusive
  if dirsep == "\\" then
    is_exclusive = last == "/" or last == "\\"
  else
    is_exclusive = last == dirsep
  end
  directory = normalize_dir(directory)
  do
    local prefix_start = output_to
    if prefix_start then
      if is_exclusive then
        prefix_map[directory] = prefix_start .. parse_subtree(directory)
      else
        prefix_map[directory] = prefix_start .. directory
      end
    else
      prefix_map[directory] = directory
    end
  end
end
output_for = function(output_to, prefix_map, path, path_type)
  if not (path_type == "directory") then
    path = convert_path(path)
  end
  for prefix_path, prefix_output in pairs(prefix_map) do
    local _continue_0 = false
    repeat
      if #path < #prefix_path then
        _continue_0 = true
        break
      end
      if path:sub(1, #prefix_path) == prefix_path then
        local output_path = prefix_output .. path:sub(#prefix_path + 1, #path)
        return output_path
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  if output_to then
    path = output_to .. path
  end
  return path
end
process_filesystem_tree = function(root, directory_callback, file_callback)
  root = normalize_dir(root)
  if directory_callback then
    directory_callback(root)
  end
  local ok, _iter, dirobj = pcall(lfs.dir, root)
  if not (ok) then
    return 
  end
  while true do
    local filename = dirobj:next()
    if not (filename) then
      break
    end
    if not (filename:match("^%.")) then
      local fpath = root .. filename
      local mode = lfs.attributes(fpath, "mode")
      local _exp_0 = mode
      if "directory" == _exp_0 then
        fpath = fpath .. '/'
        process_filesystem_tree(fpath, directory_callback, file_callback)
      elseif "file" == _exp_0 then
        if file_callback then
          file_callback(fpath)
        end
      elseif nil == _exp_0 then
        local _ = nil
      else
        error("Unexpected filetype " .. tostring(mode))
      end
    end
  end
end
return {
  main = main,
  mkdir = mkdir,
  gettime = gettime,
  format_time = format_time,
  compile_file_text = compile_file_text,
  compile_and_write = compile_and_write,
  process_filesystem_tree = process_filesystem_tree,
  parse_cli_paths = parse_cli_paths,
  output_for = output_for
}
