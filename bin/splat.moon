#!/usr/bin/env moon

-- concatenate a collection of lua modules into one

require "lfs"

import insert, concat from table
import dump from require "moonscript.util"

if not arg[1]
  print "usage: splat directory"
  os.exit!

dir = arg[1]

normalize = (path) ->
  path\match("(.-)/*$").."/"

scan_directory = (root, patt, collected={}) ->
  root = normalize root
  for fname in lfs.dir root
    if not fname\match "^%."
      full_path = root..fname

      if lfs.attributes(full_path, "mode") == "directory"
        scan_directory full_path, patt, collected
      else
        if full_path\match patt
          insert collected, full_path

  collected

files = scan_directory dir, "%.lua$"

modules = {}

path_to_module_name = (path) ->
  (path\match("(.-)%.lua")\gsub("/", "."))

each_line = (text) ->
  import yield from coroutine
  coroutine.wrap ->
    start = 1
    while true
      pos, after = text\find "\n", start, true
      break if not pos
      yield text\sub start, pos - 1
      start = after + 1
    yield text\sub start, #text
    nil

write_module = (name, text) ->
  print "package.preload['"..name.."'] = function()"
  for line in each_line text
    print "  "..line
  print "end"

modules = {}
chunks = for path in *files
  module_name = path_to_module_name path
  content = io.open(path)\read"*a"
  modules[module_name] = true
  {module_name, content}

for chunk in *chunks
  name, content = unpack chunk
  base, init = name\match"(.-)%.init"
  if base and not modules[base] then
    modules[base] = true
    name = base
  write_module name, content

default_name = if arg[2]
  arg[2]
else
  dir\gsub("/", ".")\gsub("%.$", "")

if modules[default_name]
  print ([[return package.preload["%s"]()]])\format default_name

