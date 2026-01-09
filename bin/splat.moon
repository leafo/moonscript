#!/usr/bin/env moon
argparse = require "argparse"

-- TODO: it would be cool if you could just point this at a luarocks tree, pass a list of top level module names, and it figures it out for you.
-- Perhaps even merge the header generation into here as well to avoid using xxd

normalize = (path) ->
  path\match("(.-)/*$").."/"

parser = argparse "splat.moon", "Concatenate a collection of Lua modules into a single file"
parser\option("--load -l", "Module names that will be load on require")\count "*"
parser\flag("--strip-prefix -s", "Strip directory prefix from module names")

parser\argument("directories", "Directories to scan for Lua modules")\args "+"

args = parser\parse [v for _, v in ipairs _G.arg]
dirs = args.directories
strip_prefix = args.strip_prefix

lfs = require "lfs"
scan_directory = (root, patt, collected={}) ->
  root = normalize root
  for fname in lfs.dir root
    if not fname\match "^%."
      full_path = root..fname

      if lfs.attributes(full_path, "mode") == "directory"
        scan_directory full_path, patt, collected
      else
        if full_path\match patt
          table.insert collected, full_path

  collected

path_to_module_name = (path, prefix) ->
  if prefix and path\sub(1, #prefix) == prefix
    path = path\sub(#prefix + 1)
  (path\match("(.-)%.lua")\gsub("/", "."))

each_line = (text) ->
  coroutine.wrap ->
    start = 1
    while true
      pos, after = text\find "\n", start, true
      break if not pos
      coroutine.yield text\sub start, pos - 1
      start = after + 1
    coroutine.yield text\sub start, #text
    nil

write_module = (name, text) ->
  print "package.preload['"..name.."'] = function()"
  for line in each_line text
    print "  "..line
  print "end"

modules = {}
for dir in *dirs
  files = scan_directory dir, "%.lua$"
  prefix = strip_prefix and normalize(dir) or nil
  chunks = for path in *files
    module_name = path_to_module_name path, prefix
    content = io.open(path)\read"*a"
    modules[module_name] = true
    {module_name, content}

  for chunk in *chunks
    name, content = unpack chunk
    base = name\match"(.-)%.init"
    if base and not modules[base] then
      modules[base] = true
      name = base
    write_module name, content

for module_name in *args.load
  if modules[module_name]
    print ([[package.preload["%s"]()]])\format module_name

