module("moonscript", package.seeall)
require("moonscript.compile")
require("moonscript.parse")
require("moonscript.util")
local concat, insert = table.concat, table.insert
local split, dump = util.split, util.dump
local lua = {
  loadstring = loadstring,
  load = load
}
dirsep = "/"
line_tables = { }
local create_moonpath
create_moonpath = function(package_path)
  local paths = split(package_path, ";")
  for i, path in ipairs(paths) do
    local p = path:match("^(.-)%.lua$")
    if p then
      paths[i] = p .. ".moon"
    end
  end
  return concat(paths, ";")
end
to_lua = function(text)
  local tree, err = parse.string(text)
  if not tree then
    error("Parse error: " .. err, 2)
  end
  local code, ltable, pos = compile.tree(tree)
  if not code then
    error(compile.format_error(ltable, pos, text), 2)
  end
  return code, ltable
end
moon_chunk = function(text, source_path)
  local code, ltable = to_lua(text)
  if source_path then
    line_tables[source_path] = ltable
  end
  local runner
  runner = function()
    do
      local _with_0 = code
      code = nil
      return _with_0
    end
  end
  return lua.load(runner, source_path)
end
moon_loader = function(name)
  local name_path = name:gsub("%.", dirsep)
  local file, file_path = nil, nil
  local _list_0 = split(package.moonpath, ";")
  for _index_0 = 1, #_list_0 do
    local path = _list_0[_index_0]
    file_path = path:gsub("?", name_path)
    file = io.open(file_path)
    if file then
      break
    end
  end
  if file then
    local text = file:read("*a")
    if not text then
      error("Could not read file", 2)
    end
    return moon_chunk(file, file_path)
  else
    return nil, "Could not find moon file"
  end
end
if not package.moonpath then
  package.moonpath = create_moonpath(package.path)
end
local init_loader
init_loader = function()
  return insert(package.loaders, 2, moon_loader)
end
if not _G.moon_no_loader then
  init_loader()
end
loadstring = function(str)
  local code = to_lua(str)
  return lua.loadstring(code)
end
loadfile = function(fname)
  local file, err = io.open(fname)
  if not file then
    return nil, err
  end
  return loadstring(file:read("*a"))
end
dofile = function(fname)
  local f = assert(loadfile(fname))
  return f()
end
