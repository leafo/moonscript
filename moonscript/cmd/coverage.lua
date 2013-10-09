local log
log = function(str)
  if str == nil then
    str = ""
  end
  return io.stderr:write(str .. "\n")
end
local create_counter
create_counter = function()
  return setmetatable({ }, {
    __index = function(self, name)
      do
        local tbl = setmetatable({ }, {
          __index = function(self)
            return 0
          end
        })
        self[name] = tbl
        return tbl
      end
    end
  })
end
local position_to_lines
position_to_lines = function(file_content, positions)
  local lines = { }
  local current_pos = 0
  local line_no = 1
  for char in file_content:gmatch(".") do
    do
      local count = rawget(positions, current_pos)
      if count then
        lines[line_no] = count
      end
    end
    if char == "\n" then
      line_no = line_no + 1
    end
    current_pos = current_pos + 1
  end
  return lines
end
local format_file
format_file = function(fname, positions)
  local file = assert(io.open(fname))
  local content = file:read("*a")
  file:close()
  local lines = position_to_lines(content, positions)
  log("------| @" .. tostring(fname))
  local line_no = 1
  for line in (content .. "\n"):gmatch("(.-)\n") do
    local foramtted_no = ("% 5d"):format(line_no)
    local sym = lines[line_no] and "*" or " "
    log(tostring(sym) .. tostring(foramtted_no) .. "| " .. tostring(line))
    line_no = line_no + 1
  end
  return log()
end
local CodeCoverage
do
  local _base_0 = {
    reset = function(self)
      self.line_counts = create_counter()
    end,
    start = function(self)
      return debug.sethook((function()
        local _base_1 = self
        local _fn_0 = _base_1.process_line
        return function(...)
          return _fn_0(_base_1, ...)
        end
      end)(), "l")
    end,
    stop = function(self)
      return debug.sethook()
    end,
    print_results = function(self)
      return self:format_results()
    end,
    process_line = function(self, _, line_no)
      local debug_data = debug.getinfo(2, "S")
      local source = debug_data.source
      self.line_counts[source][line_no] = self.line_counts[source][line_no] + 1
    end,
    format_results = function(self)
      local line_table = require("moonscript.line_tables")
      local positions = create_counter()
      for file, lines in pairs(self.line_counts) do
        local _continue_0 = false
        repeat
          local file_table = line_table[file]
          if not (file_table) then
            _continue_0 = true
            break
          end
          for line, count in pairs(lines) do
            local _continue_1 = false
            repeat
              local position = file_table[line]
              if not (position) then
                _continue_1 = true
                break
              end
              positions[file][position] = positions[file][position] + count
              _continue_1 = true
            until true
            if not _continue_1 then
              break
            end
          end
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      for file, ps in pairs(positions) do
        format_file(file, ps)
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      return self:reset()
    end,
    __base = _base_0,
    __name = "CodeCoverage"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  CodeCoverage = _class_0
end
return {
  CodeCoverage = CodeCoverage
}
