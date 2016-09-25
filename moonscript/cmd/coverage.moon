
log = (str="") ->
  io.stderr\write str .. "\n"

create_counter = ->
  setmetatable {}, __index: (name) =>
    with tbl = setmetatable {}, __index: => 0
      @[name] = tbl

position_to_lines = (file_content, positions) ->
  lines = {}
  current_pos = 0
  line_no = 1
  for char in file_content\gmatch "."
    if count = rawget positions, current_pos
      lines[line_no] = count

    if char == "\n"
      line_no += 1

    current_pos += 1

  lines

format_file = (fname, positions) ->
  -- sources have @ in front of file names
  fname = fname\gsub "^@", ""

  file = assert io.open fname
  content = file\read "*a"
  file\close!

  lines = position_to_lines content, positions
  log "------| @#{fname}"
  line_no = 1
  for line in (content .. "\n")\gmatch "(.-)\n"
    foramtted_no = "% 5d"\format(line_no)
    sym = lines[line_no] and "*" or " "
    log "#{sym}#{foramtted_no}| #{line}"
    line_no += 1

  log!


class CodeCoverage
  new: =>
    @reset!

  reset: =>
    @line_counts = create_counter!

  start: =>
    debug.sethook @\process_line, "l"

  stop: =>
    debug.sethook!

  print_results: =>
    @format_results!

  process_line: (_, line_no) =>
    debug_data = debug.getinfo 2, "S"
    source = debug_data.source
    @line_counts[source][line_no] += 1

  format_results: =>
    line_table = require "moonscript.line_tables"
    positions = create_counter!

    for file, lines in pairs @line_counts
      file_table = line_table[file]
      continue unless file_table

      for line, count in pairs lines
        position = file_table[line]
        continue unless position
        positions[file][position] += count

    for file, ps in pairs positions
      format_file file, ps

{ :CodeCoverage }
