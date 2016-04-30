local unpack
unpack = require("moonscript.util").unpack
local parse_spec
parse_spec = function(spec)
  local flags, words
  if type(spec) == "table" then
    flags, words = unpack(spec), spec
  else
    flags, words = spec, { }
  end
  assert("no flags for arguments")
  local out = { }
  for part in flags:gmatch("%w:?") do
    if part:match(":$") then
      out[part:sub(1, 1)] = {
        value = true
      }
    else
      out[part] = { }
    end
  end
  return out
end
local parse_arguments
parse_arguments = function(spec, args)
  spec = parse_spec(spec)
  local out = { }
  local remaining = { }
  local last_flag = nil
  for _index_0 = 1, #args do
    local _continue_0 = false
    repeat
      local arg = args[_index_0]
      local group = { }
      if last_flag then
        out[last_flag] = arg
        _continue_0 = true
        break
      end
      do
        local flag = arg:match("-(%w+)")
        if flag then
          do
            local short_name = spec[flag]
            if short_name then
              out[short_name] = true
            else
              for char in flag:gmatch(".") do
                out[char] = true
              end
            end
          end
          _continue_0 = true
          break
        end
      end
      table.insert(remaining, arg)
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  return out, remaining
end
return {
  parse_arguments = parse_arguments,
  parse_spec = parse_spec
}
