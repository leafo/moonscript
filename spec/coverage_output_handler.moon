
load_line_table = (chunk_name) ->
  import to_lua from require "moonscript.base"

  return unless chunk_name\match "^@"
  fname = chunk_name\sub 2

  file = assert io.open fname
  code = file\read "*a"
  file\close!

  c, ltable = to_lua code

  return nil, ltable unless c

  line_tables = require "moonscript.line_tables"
  line_tables[chunk_name] = ltable
  true

(options) ->
  busted = require "busted"
  handler = require("busted.outputHandlers.utfTerminal") options

  local spec_name

  coverage = require "moonscript.cmd.coverage"
  cov = coverage.CodeCoverage!

  busted.subscribe { "test", "start" }, (context) ->
    cov\start!

  busted.subscribe { "test", "end" }, ->
    cov\stop!

  busted.subscribe { "suite", "end" }, (context) ->
    line_counts = {}

    for chunk_name, counts in pairs cov.line_counts
      continue unless chunk_name\match("^@$./") or chunk_name\match "@[^/]"
      continue if chunk_name\match "^@spec/"

      if chunk_name\match "%.lua$"
        chunk_name = chunk_name\gsub "lua$", "moon"
        continue unless load_line_table chunk_name

      line_counts[chunk_name] = counts

    cov.line_counts = line_counts
    cov\format_results!

  handler
