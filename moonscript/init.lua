module("moonscript", package.seeall)
require("moonscript.compile")
require("moonscript.parse")
require("moonscript.util")
local concat, insert = table.concat, table.insert
local split, dump = util.split, util.dump
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
moon_chunk = function(file, file_path)
  local text = file:read("*a")
  if not text then
    error("Could not read file")
  end
  local tree, err = parse.string(text)
  if not tree then
    error("Parse error: " .. err)
  end
  local code, ltable, pos = compile.tree(tree)
  if not code then
    error(compile.format_error(ltable, pos, text))
  end
  line_tables[file_path] = ltable
  local runner
  runner = function()
    do
      local _with_0 = code
      code = nil
      return _with_0
    end
  end
  return load(runner, file_path)
end
moon_loader = function(name)
  local name_path = name:gsub("%.", dirsep)
  local file, file_path = nil, nil
  do
    local _item_0 = split(package.moonpath, ";")
    for _index_0 = 1, #_item_0 do
      local path = _item_0[_index_0]
      file_path = path:gsub("?", name_path)
      file = io.open(file_path)
      if file then
        break
      end
    end
  end
  if file then
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
