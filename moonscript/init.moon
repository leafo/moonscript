
module "moonscript", package.seeall

require "moonscript.compile"
require "moonscript.parse"
require "moonscript.util"

import concat, insert from table
import split, dump from util

lua = :loadstring

export to_lua, moon_chunk, moon_loader, dirsep, line_tables
export dofile, loadfile, loadstring

dirsep = "/"
line_tables = {}

-- create moon path package from lua package path
create_moonpath = (package_path) ->
  paths = split package_path, ";"
  for i, path in ipairs paths
    p = path\match "^(.-)%.lua$"
    if p then paths[i] = p..".moon"
  concat paths, ";"

to_lua = (text) ->
  if "string" != type text
    t = type text
    error "expecting string (got ".. t ..")", 2

  tree, err = parse.string text
  if not tree
    error err, 2

  code, ltable, pos = compile.tree tree
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
    loadstring text, file_path
  else
    nil, "Could not find moon file"

if not package.moonpath
  package.moonpath = create_moonpath package.path

init_loader = ->
  insert package.loaders, 2, moon_loader

init_loader! if not _G.moon_no_loader

loadstring = (str, chunk_name) ->
  passed, code, ltable = pcall -> to_lua str
  if not passed
    error chunk_name .. ": " .. code, 2

  line_tables[chunk_name] = ltable if chunk_name
  lua.loadstring code, chunk_name or "=(moonscript.loadstring)"

loadfile = (fname) ->
  file, err = io.open fname
  return nil, err if not file
  text = assert file\read "*a"
  loadstring text, fname

-- throws errros
dofile = (fname) ->
  f = assert loadfile fname
  f!

