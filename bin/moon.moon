
alt_getopt = require "alt_getopt"

moonscript = require "moonscript.base"
util = require "moonscript.util"
errors = require "moonscript.errors"

unpack = util.unpack

opts, ind = alt_getopt.get_opts arg, "cvhd", {
  version: "v"
  help: "h"
}

help = [=[Usage: %s [options] [script [args]]

    -h          Print this message
    -d          Disable stack trace rewriting
    -c          Collect and print code coverage
    -v          Print version
]=]


print_err = (...) ->
  msg = table.concat [tostring v for v in *{...}], "\t"
  io.stderr\write msg .. "\n"

print_help = (err) ->
  help = help\format arg[0]

  if err
    print_err err
    print_err help
  else
    print help

  os.exit!

run = ->
  if opts.h
    print_help!

  if opts.v
    require("moonscript.version").print_version!
    os.exit!

  script_fname = arg[ind]

  unless script_fname
    print_help "REPL not yet supported"

  new_arg = {
    [-1]: arg[0],
    [0]: arg[ind],
    select ind + 1, unpack arg
  }

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

  util.getfenv(moonscript_chunk).arg = new_arg

  run_chunk = ->
    moonscript.insert_loader!
    moonscript_chunk unpack new_arg
    moonscript.remove_loader!

  if opts.d
    return run_chunk!

  local err, trace, cov

  if opts.c
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
