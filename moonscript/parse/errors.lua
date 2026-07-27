local errors = {}

-- Split subject into array of lines (local helper)
local function splitlines(subject)
  local lines = {}
  local start = 1
  while true do
    local newline_pos = subject:find("\n", start, true)
    if newline_pos then
      lines[#lines + 1] = subject:sub(start, newline_pos - 1)
      start = newline_pos + 1
    else
      lines[#lines + 1] = subject:sub(start)
      break
    end
  end
  return lines
end

-- Calculate line number and column from byte position (local helper)
-- Returns: line (1-indexed), column (1-indexed)
local function calcline(subject, pos)
  if pos <= 1 then return 1, 1 end
  local sub = subject:sub(1, pos - 1)
  local line = 1
  local last_newline = 0
  for i = 1, #sub do
    if sub:sub(i, i) == "\n" then
      line = line + 1
      last_newline = i
    end
  end
  local col = pos - last_newline
  return line, col
end

-- Get the line of text containing the given position (local helper)
-- Returns: line text, column position within that line
local function getline(subject, pos)
  -- Find start of line
  local line_start = pos
  while line_start > 1 and subject:sub(line_start - 1, line_start - 1) ~= "\n" do
    line_start = line_start - 1
  end
  -- Find end of line
  local line_end = pos
  while line_end <= #subject and subject:sub(line_end, line_end) ~= "\n" do
    line_end = line_end + 1
  end
  return subject:sub(line_start, line_end - 1), pos - line_start + 1
end

-- Format a complete error message
-- subject: the input string being parsed
-- pos: byte position where error occurred (1-indexed)
-- label: error label from T() or nil
-- opts: optional table with:
--   color: boolean - if true, use ansicolors for colored output
--   context: number - lines to show above and below error line (default: 0)
function errors.format(subject, pos, label, opts)
  local line, col = calcline(subject, pos)
  local line_text, col_in_line = getline(subject, pos)
  local context = opts and opts.context or 0

  local msg
  if opts and opts.color then
    local colors = require("ansicolors")
    msg = colors("%{bright red}" .. (label or "error") .. "%{reset}")
    msg = msg .. colors(" %{dim}at line " .. line .. ", column " .. col .. ":%{reset}\n")

    if context > 0 then
      local lines = splitlines(subject)
      local start_line = math.max(1, line - context)
      local end_line = math.min(#lines, line + context)
      local max_line_num = end_line
      local line_num_width = #tostring(max_line_num)

      for i = start_line, end_line do
        local line_num_str = string.format("%" .. line_num_width .. "d", i)
        msg = msg .. colors("%{dim}" .. line_num_str .. " |%{reset} ") .. lines[i] .. "\n"
        if i == line then
          local prefix_width = line_num_width + 3 + col_in_line - 1
          msg = msg .. string.rep(" ", prefix_width) .. colors("%{bright red}^%{reset}") .. "\n"
        end
      end
      msg = msg:sub(1, -2) -- remove trailing newline
    else
      msg = msg .. "  " .. line_text .. "\n"
      msg = msg .. "  " .. string.rep(" ", col_in_line - 1)
      msg = msg .. colors("%{bright red}^%{reset}")
    end
  else
    msg = string.format("%s at line %d, column %d:\n",
      label or "error", line, col)

    if context > 0 then
      local lines = splitlines(subject)
      local start_line = math.max(1, line - context)
      local end_line = math.min(#lines, line + context)
      local max_line_num = end_line
      local line_num_width = #tostring(max_line_num)

      for i = start_line, end_line do
        local line_num_str = string.format("%" .. line_num_width .. "d", i)
        msg = msg .. line_num_str .. " | " .. lines[i] .. "\n"
        if i == line then
          local prefix_width = line_num_width + 3 + col_in_line - 1
          msg = msg .. string.rep(" ", prefix_width) .. "^\n"
        end
      end
      msg = msg:sub(1, -2) -- remove trailing newline
    else
      msg = msg .. "  " .. line_text .. "\n"
      msg = msg .. "  " .. string.rep(" ", col_in_line - 1) .. "^"
    end
  end

  return msg
end

return errors
