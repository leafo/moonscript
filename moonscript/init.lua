local compile = require("moonscript.compile")
local parse = require("moonscript.parse")
local concat, insert = table.concat, table.insert
local split, dump, get_options, unpack
do
  local _table_0 = require("moonscript.util")
  split, dump, get_options, unpack = _table_0.split, _table_0.dump, _table_0.get_options, _table_0.unpack
end
local lua = {
  loadstring = loadstring
}
local dirsep = "/"
local line_tables = require("moonscript.line_tables")
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
local to_lua
to_lua = function(text, options)
  if options == nil then
    options = { }
  end
  if "string" ~= type(text) then
    local t = type(text)
    error("expecting string (got " .. t .. ")", 2)
  end
  local tree, err = parse.string(text)
  if not tree then
    error(err, 2)
  end
  local code, ltable, pos = compile.tree(tree, options)
  if not code then
    error(compile.format_error(ltable, pos, text), 2)
  end
  return code, ltable
end
local loadstring
loadstring = function(...)
  local options, str, chunk_name, mode, env = get_options(...)
  chunk_name = chunk_name or "=(moonscript.loadstring)"
  local passed, code, ltable = pcall(function()
    return to_lua(str, options)
  end)
  if not passed then
    error(chunk_name .. ": " .. code, 2)
  end
  if chunk_name then
    line_tables[chunk_name] = ltable
  end
  return (lua.loadstring or lua.load)(code, chunk_name, unpack({
    mode,
    env
  }))
end
local loadfile
loadfile = function(fname, ...)
  local file, err = io.open(fname)
  if not file then
    return nil, err
  end
  local text = assert(file:read("*a"))
  file:close()
  return loadstring(text, fname, ...)
end
local dofile
dofile = function(...)
  local f = assert(loadfile(...))
  return f()
end
local moon_loader
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
    file:close()
    return loadstring(text, file_path)
  else
    return nil, "Could not find moon file"
  end
end
if not package.moonpath then
  package.moonpath = create_moonpath(package.path)
end
local init_loader
init_loader = function()
  return insert(package.loaders or package.searchers, 2, moon_loader)
end
if not (_G.moon_no_loader) then
  init_loader()
end
return {
  _NAME = "moonscript",
  to_lua = to_lua,
  moon_chunk = moon_chunk,
  moon_loader = moon_loader,
  dirsep = dirsep,
  dofile = dofile,
  loadfile = loadfile,
  loadstring = loadstring
}
