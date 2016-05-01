import unpack from require "moonscript.util"
parse_spec = (spec) ->
  flags, words = if type(spec) == "table"
    unpack(spec), spec
  else
    spec, {}

  assert "no flags for arguments"

  out = {}
  for part in flags\gmatch "%w:?"
    if part\match ":$"
      out[part\sub 1,1] = { value: true }
    else
      out[part] = {}

  out

parse_arguments = (spec, args) ->
  spec = parse_spec spec

  out = {}

  remaining = {}
  last_flag = nil

  for arg in *args
    group = {}
    if last_flag
      out[last_flag] = arg
      continue

    if flag = arg\match "-(%w+)"
      if short_name = spec[flag]
        out[short_name] = true
      else
        for char in flag\gmatch "."
          out[char] = true
      continue

    table.insert remaining, arg

  out, remaining



{ :parse_arguments, :parse_spec }
