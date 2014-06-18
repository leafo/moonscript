local lfs = require("lfs")
local split
do
  local _obj_0 = require("moonscript.util")
  split = _obj_0.split
end
local dirsep = package.config:sub(1, 1)
local dirsep_chars
if dirsep == "\\" then
  dirsep_chars = "\\/"
else
  dirsep_chars = dirsep
end
local mkdir
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
local normalize_dir
normalize_dir = function(path)
  return path:match("^(.-)[" .. tostring(dirsep_chars) .. "]*$") .. dirsep
end
local parse_dir
parse_dir = function(path)
  return (path:match("^(.-)[^" .. tostring(dirsep_chars) .. "]*$"))
end
local parse_file
parse_file = function(path)
  return (path:match("^.-([^" .. tostring(dirsep_chars) .. "]*)$"))
end
local convert_path
convert_path = function(path)
  local new_path = path:gsub("%.moon$", ".lua")
  if new_path == path then
    new_path = path .. ".lua"
  end
  return new_path
end
local format_time
format_time = function(time)
  return ("%.3fms"):format(time * 1000)
end
local gettime
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
local compile_file_text
compile_file_text = function(text, fname, opts)
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
    dump.tree(tree)
    return nil
  end
  local compile_time
  if opts.benchmark then
    compile_time = gettime()
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
    do
      local _obj_0 = require("moonscript.util")
      debug_posmap = _obj_0.debug_posmap
    end
    print("Pos", "Lua", ">>", "Moon")
    print(debug_posmap(posmap_or_err, text, code))
    return nil
  end
  if opts.benchmark then
    print(table.concat({
      fname,
      "Parse time  \t" .. format_time(parse_time),
      "Compile time\t" .. format_time(compile_time),
      ""
    }, "\n"))
    return nil
  end
  return code
end
return {
  dirsep = dirsep,
  mkdir = mkdir,
  normalize_dir = normalize_dir,
  parse_dir = parse_dir,
  parse_file = parse_file,
  new_path = new_path,
  convert_path = convert_path,
  gettime = gettime,
  format_time = format_time,
  compile_file_text = compile_file_text
}
