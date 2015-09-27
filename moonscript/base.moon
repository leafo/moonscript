compile = require "moonscript.compile"
parse = require "moonscript.parse"

import concat, insert, remove from table
import split, dump, get_options, unpack from require "moonscript.util"

lua = :loadstring, :load

local *

dirsep = "/"
line_tables = require "moonscript.line_tables"

-- create moon path package from lua package path
create_moonpath = (package_path) ->
  moonpaths = for path in *split package_path, ";"
    prefix = path\match "^(.-)%.lua$"
    continue unless prefix
    prefix .. ".moon"
  concat moonpaths, ";"

to_lua = (text, options={}) ->
  if "string" != type text
    t = type text
    return nil, "expecting string (got ".. t ..")"

  tree, err = parse.string text
  if not tree
    return nil, err

  code, ltable, pos = compile.tree tree, options
  if not code
    return nil, compile.format_error(ltable, pos, text)

  code, ltable

moon_loader = (name) ->
  name_path = name\gsub "%.", dirsep

  local file, file_path
  for path in package.moonpath\gmatch "[^;]+"
    file_path = path\gsub "?", name_path
    file = io.open file_path
    break if file

  if file
    text = file\read "*a"
    file\close!
    res, err = loadstring text, "@#{file_path}"
    if not res
        error file_path .. ": " .. err

    return res

  return nil, "Could not find moon file"


loadstring = (...) ->
  options, str, chunk_name, mode, env = get_options ...
  chunk_name or= "=(moonscript.loadstring)"

  code, ltable_or_err = to_lua str, options
  unless code
    return nil, ltable_or_err

  line_tables[chunk_name] = ltable_or_err if chunk_name
  -- the unpack prevents us from passing nil
  (lua.loadstring or lua.load) code, chunk_name, unpack { mode, env }

loadfile = (fname, ...) ->
  file, err = io.open fname
  return nil, err unless file
  text = assert file\read "*a"
  file\close!
  loadstring text, "@#{fname}", ...

-- throws errros
dofile = (...) ->
  f = assert loadfile ...
  f!

insert_loader = (pos=2) ->
  if not package.moonpath
    package.moonpath = create_moonpath package.path

  loaders = package.loaders or package.searchers
  for loader in *loaders
    return false if loader == moon_loader

  insert loaders, pos, moon_loader
  true

remove_loader = ->
  loaders = package.loaders or package.searchers

  for i, loader in ipairs loaders
    if loader == moon_loader
      remove loaders, i
      return true

  false

{
  _NAME: "moonscript"
  :insert_loader, :remove_loader, :to_lua, :moon_loader, :dirsep,
  :dofile, :loadfile, :loadstring, :create_moonpath
}

