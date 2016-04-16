
parse_arguments = (spec, args) ->
  out = {}

  remaining = {}
  last_flag = nil

  for arg in *args
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



{:parse_arguments}
