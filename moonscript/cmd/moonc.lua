local lfs = require("lfs")
local split
split = require("moonscript.util").split
local dirsep, dirsep_chars, mkdir, normalize_dir, parse_dir, parse_file, convert_path, format_time, gettime, compile_file_text, write_file, compile_and_write, is_abs_path, path_to_target
dirsep = package.config:sub(1, 1)
if dirsep == "\\" then
  dirsep_chars = "\\/"
else
  dirsep_chars = dirsep
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
normalize_dir = function(path)
  return path:match("^(.-)[" .. tostring(dirsep_chars) .. "]*$") .. dirsep
end
parse_dir = function(path)
  return (path:match("^(.-)[^" .. tostring(dirsep_chars) .. "]*$"))
end
parse_file = function(path)
  return (path:match("^.-([^" .. tostring(dirsep_chars) .. "]*)$"))
end
convert_path = function(path)
  local new_path = path:gsub("%.moon$", ".lua")
  if new_path == path then
    new_path = path .. ".lua"
  end
  return new_path
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
      opts.fname or "stdin",
      "Parse time  \t" .. format_time(parse_time),
      "Compile time\t" .. format_time(compile_time),
      ""
    }, "\n"))
    return true
  end
  return code
end
write_file = function(fname, code)
  mkdir(parse_dir(fname))
  local f, err = io.open(fname, "w")
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
is_abs_path = function(path)
  local first = path:sub(1, 1)
  if dirsep == "\\" then
    return first == "/" or first == "\\" or path:sub(2, 1) == ":"
  else
    return first == dirsep
  end
end
path_to_target = function(path, target_dir, base_dir)
  if target_dir == nil then
    target_dir = nil
  end
  if base_dir == nil then
    base_dir = nil
  end
  local target = convert_path(path)
  if target_dir then
    target_dir = normalize_dir(target_dir)
  end
  if base_dir and target_dir then
    local head = base_dir:match("^(.-)[^" .. tostring(dirsep_chars) .. "]*[" .. tostring(dirsep_chars) .. "]?$")
    if head then
      local start, stop = target:find(head, 1, true)
      if start == 1 then
        target = target:sub(stop + 1)
      end
    end
  end
  if target_dir then
    if is_abs_path(target) then
      target = parse_file(target)
    end
    target = target_dir .. target
  end
  return target
end
return {
  dirsep = dirsep,
  mkdir = mkdir,
  normalize_dir = normalize_dir,
  parse_dir = parse_dir,
  parse_file = parse_file,
  convert_path = convert_path,
  gettime = gettime,
  format_time = format_time,
  path_to_target = path_to_target,
  compile_file_text = compile_file_text,
  compile_and_write = compile_and_write
}
