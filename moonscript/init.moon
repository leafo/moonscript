
compile = require "moonscript.compile"
parse = require "moonscript.parse"

import concat, insert from table
import split, dump, get_options, unpack from require "moonscript.util"

lua = :loadstring

dirsep = "/"
line_tables = require "moonscript.line_tables"

-- create moon path package from lua package path
create_moonpath = (package_path) ->
  paths = split package_path, ";"
  for i, path in ipairs paths
    p = path\match "^(.-)%.lua$"
    if p then paths[i] = p..".moon"
  concat paths, ";"

to_lua = (text, options={}) ->
  if "string" != type text
    t = type text
    error "expecting string (got ".. t ..")", 2

  tree, err = parse.string text
  if not tree
    error err, 2

  code, ltable, pos = compile.tree tree, options
  if not code
    error compile.format_error(ltable, pos, text), 2

  code, ltable

moon_loader = (name) ->
  name_path = name\gsub "%.", dirsep

  file, file_path = nil, nil
  for path in *split package.moonpath, ";"
    file_path = path\gsub "?", name_path
    file = io.open file_path
    break if file

  if file
    text = file\read "*a"
    file\close!
    loadstring text, file_path
  else
    nil, "Could not find moon file"

if not package.moonpath
  package.moonpath = create_moonpath package.path

init_loader = ->
  insert package.loaders or package.searchers, 2, moon_loader

init_loader! unless _G.moon_no_loader

loadstring = (...) ->
  options, str, chunk_name, mode, env = get_options ...
  chunk_name or= "=(moonscript.loadstring)"

  passed, code, ltable = pcall -> to_lua str, options
  if not passed
    error chunk_name .. ": " .. code, 2

  line_tables[chunk_name] = ltable if chunk_name
  -- the unpack prevents us from passing nil
  (lua.loadstring or lua.load) code, chunk_name, unpack { mode, env }

loadfile = (fname, ...) ->
  file, err = io.open fname
  return nil, err if not file
  text = assert file\read "*a"
  file\close!
  loadstring text, fname, ...

-- throws errros
dofile = (...) ->
  f = assert loadfile ...
  f!

{
  _NAME: "moonscript"
  :to_lua, :moon_chunk, :moon_loader, :dirsep, :dofile, :loadfile,
  :loadstring
}

