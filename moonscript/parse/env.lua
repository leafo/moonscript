local getfenv, setfenv
do
  local _obj_0 = require("moonscript.util")
  getfenv, setfenv = _obj_0.getfenv, _obj_0.setfenv
end
local wrap_env
wrap_env = function(debug, fn)
  local V, Cmt
  do
    local _obj_0 = require("lpeg")
    V, Cmt = _obj_0.V, _obj_0.Cmt
  end
  local env = getfenv(fn)
  local wrap_name = V
  if debug then
    local indent = 0
    local indent_char = "  "
    local iprint
    iprint = function(...)
      local args = table.concat((function(...)
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = {
          ...
        }
        for _index_0 = 1, #_list_0 do
          local a = _list_0[_index_0]
          _accum_0[_len_0] = tostring(a)
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)(...), ", ")
      return io.stderr:write(tostring(indent_char:rep(indent)) .. tostring(args) .. "\n")
    end
    wrap_name = function(name)
      local v = V(name)
      v = Cmt("", function(str, pos)
        local rest = str:sub(pos, -1):match("^([^\n]*)")
        iprint("* " .. tostring(name) .. " (" .. tostring(rest) .. ")")
        indent = indent + 1
        return true
      end) * Cmt(v, function(str, pos, ...)
        iprint(name, true)
        indent = indent - 1
        return true, ...
      end) + Cmt("", function()
        iprint(name, false)
        indent = indent - 1
        return false
      end)
      return v
    end
  end
  return setfenv(fn, setmetatable({ }, {
    __index = function(self, name)
      local value = env[name]
      if value ~= nil then
        return value
      end
      if name:match("^[A-Z][A-Za-z0-9]*$") then
        local v = wrap_name(name)
        return v
      end
      return error("unknown variable referenced: " .. tostring(name))
    end
  }))
end
return {
  wrap_env = wrap_env
}
