argparse = require "argparse"

moonscript = require "moonscript.base"
util = require "moonscript.util"
errors = require "moonscript.errors"

unpack = util.unpack

argparser = argparse! name: "moon"

argparser\argument "script"
argparser\argument("args")\args "*"
argparser\option "-c --coverage", "Collect and print code coverage"
argparser\option "-d", "Disable stack trace rewriting"
argparser\option "-v --version", "Print version information"

base = 0
for flag in *arg
  base += 1
  break if flag\sub(1, 1) != "-"
args = {unpack arg, 1, base}
opts = argparser\parse args

print_err = (...) ->
  msg = table.concat [tostring v for v in *{...}], "\t"
  io.stderr\write msg .. "\n"

run = ->

  if opts.version
    require("moonscript.version").print_version!
    os.exit!

  script_fname = opts.script

  args = {unpack arg, base + 1}
  args[-1] = arg[0]
  args[0] = opts.script

  local moonscript_chunk, lua_parse_error

  passed, err = pcall ->
    moonscript_chunk, lua_parse_error = moonscript.loadfile script_fname, {
      implicitly_return_root: false
    }

  unless passed
    print_err err
    os.exit 1

  unless moonscript_chunk
    if lua_parse_error
      print_err lua_parse_error
    else
      print_err "Can't file file: #{script_fname}"

    os.exit 1

  util.getfenv(moonscript_chunk).arg = args

  run_chunk = ->
    moonscript.insert_loader!
    moonscript_chunk unpack args
    moonscript.remove_loader!

  if opts.d
    return run_chunk!

  local err, trace, cov

  if opts.coverage
    print "starting coverage"
    coverage = require "moonscript.cmd.coverage"
    cov = coverage.CodeCoverage!
    cov\start!

  xpcall run_chunk, (_err) ->
    err = _err
    trace = debug.traceback "", 2

  if err
    truncated = errors.truncate_traceback util.trim trace
    rewritten = errors.rewrite_traceback truncated, err

    if rewritten
      print_err rewritten
    else
      -- failed to rewrite, show original
      print_err table.concat {
        err,
        util.trim trace
      }, "\n"
  else
    if cov
      cov\stop!
      cov\print_results!

run!
