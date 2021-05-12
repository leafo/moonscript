-- Path-handling functions; these are on their own to allow test filesystem
-- stub functions to make use of them independently of the modules they are
-- testing
local *

dirsep = package.config\sub 1,1
dirsep_chars = if dirsep == "\\"
  "\\/" -- windows
else
  dirsep

is_abs_path = (path) ->
  first = path\sub 1, 1
  if dirsep == "\\"
    first == "/" or first == "\\" or path\sub(2,1) == ":"
  else
    first == dirsep

-- Strips excess / and ensures path ends with /
normalize_dir = (path) ->
  normalized_dir = if is_abs_path(path)
    dirsep
  else
    ""
  for path_element in iterate_path(path)
    normalized_dir ..= path_element .. dirsep
  return normalized_dir

-- Strips excess and trailing /
normalize_path = (path) ->
  path_elements = {}
  for path_element in iterate_path(path)
    table.insert path_elements, path_element

  normalized_path = if is_abs_path(path)
    dirsep
  else
    ""

  for i = 1, #path_elements - 1
    path_element = path_elements[i]
    normalized_path ..= path_element .. dirsep
  return normalized_path .. path_elements[#path_elements]

-- parse the directory out of a path
parse_dir = (path) ->
  (path\match "^(.-)[^#{dirsep_chars}]*$")

-- parse the filename out of a path
parse_file = (path) ->
  (path\match "^.-([^#{dirsep_chars}]*)$")

-- parse the subtree (all but the top directory) out of a path
-- Invariants:
-- If input is already normalized, the output will also be in normalized form
parse_subtree = (path) ->
  (path\match "^.-[#{dirsep_chars}]+(.*)$")

-- parse the very first directory out of a path
parse_root = (path) ->
  (path\match "^(.-[#{dirsep_chars}]+).*$")

-- converts .moon to a .lua path for calcuating compile target
convert_path = (path) ->
  new_path = path\gsub "%.moon$", ".lua"
  if new_path == path
    new_path = path .. ".lua"
  new_path

-- Iterates over the directories (and file) in a path
iterate_path = (path) ->
  path\gmatch "([^#{dirsep_chars}]+)"

{
  :dirsep
  :is_abs_path
  :normalize_dir
  :normalize_path
  :parse_dir
  :parse_file
  :parse_subtree
  :parse_root
  :convert_path
  :iterate_path
}
