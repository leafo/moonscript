local dirsep, dirsep_chars, is_abs_path, normalize_dir, normalize_path, parse_dir, parse_file, parse_subtree, parse_root, convert_path, iterate_path
dirsep = package.config:sub(1, 1)
if dirsep == "\\" then
  dirsep_chars = "\\/"
else
  dirsep_chars = dirsep
end
is_abs_path = function(path)
  local first = path:sub(1, 1)
  if dirsep == "\\" then
    return first == "/" or first == "\\" or path:sub(2, 1) == ":"
  else
    return first == dirsep
  end
end
normalize_dir = function(path)
  local normalized_dir
  if is_abs_path(path) then
    normalized_dir = dirsep
  else
    normalized_dir = ""
  end
  for path_element in iterate_path(path) do
    normalized_dir = normalized_dir .. (path_element .. dirsep)
  end
  return normalized_dir
end
normalize_path = function(path)
  local path_elements = { }
  for path_element in iterate_path(path) do
    table.insert(path_elements, path_element)
  end
  local normalized_path
  if is_abs_path(path) then
    normalized_path = dirsep
  else
    normalized_path = ""
  end
  for i = 1, #path_elements - 1 do
    local path_element = path_elements[i]
    normalized_path = normalized_path .. (path_element .. dirsep)
  end
  return normalized_path .. path_elements[#path_elements]
end
parse_dir = function(path)
  return (path:match("^(.-)[^" .. tostring(dirsep_chars) .. "]*$"))
end
parse_file = function(path)
  return (path:match("^.-([^" .. tostring(dirsep_chars) .. "]*)$"))
end
parse_subtree = function(path)
  return (path:match("^.-[" .. tostring(dirsep_chars) .. "]+(.*)$"))
end
parse_root = function(path)
  return (path:match("^(.-[" .. tostring(dirsep_chars) .. "]+).*$"))
end
convert_path = function(path)
  local new_path = path:gsub("%.moon$", ".lua")
  if new_path == path then
    new_path = path .. ".lua"
  end
  return new_path
end
iterate_path = function(path)
  return path:gmatch("([^" .. tostring(dirsep_chars) .. "]+)")
end
return {
  dirsep = dirsep,
  is_abs_path = is_abs_path,
  normalize_dir = normalize_dir,
  normalize_path = normalize_path,
  parse_dir = parse_dir,
  parse_file = parse_file,
  parse_subtree = parse_subtree,
  parse_root = parse_root,
  convert_path = convert_path,
  iterate_path = iterate_path
}
