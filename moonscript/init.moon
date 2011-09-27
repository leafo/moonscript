
module "moonscript", package.seeall

require "moonscript.compile"
require "moonscript.parse"
require "moonscript.util"

import concat, insert from table
import split, dump from util

export moon_chunk, moon_loader, dirsep, line_tables

dirsep = "/"
line_tables = {}

-- create moon path package from lua package path
create_moonpath = (package_path) ->
  paths = split package_path, ";"
  for i, path in ipairs paths
    p = path\match "^(.-)%.lua$"
    if p then paths[i] = p..".moon"
  concat paths, ";"

-- load the chunk function from a file objec:
moon_chunk = (file, file_path) ->
  text = file\read "*a"
  if not text then error "Could not read file"
  tree, err = parse.string text
  if not tree
    error "Parse error: " .. err

  code, ltable, pos = compile.tree tree
  if not code
    error compile.format_error ltable, pos, text

  line_tables[file_path] = ltable

  runner = -> with code do code = nil
  load runner, file_path

moon_loader = (name) ->
  name_path = name\gsub "%.", dirsep

  file, file_path = nil, nil
  for path in *split package.moonpath, ";"
    file_path = path\gsub "?", name_path
    file = io.open file_path
    break if file

  if file
    moon_chunk file, file_path
  else
    nil, "Could not find moon file"


if not package.moonpath
  package.moonpath = create_moonpath package.path

init_loader = ->
  insert package.loaders, 2, moon_loader

init_loader! if not _G.moon_no_loader

