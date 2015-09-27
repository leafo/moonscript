lfs = require "lfs"

import with_dev from require "spec.helpers"

pattern = ...

unpack = table.unpack or unpack

options = {
  in_dir: "spec/inputs",
  out_dir: "spec/outputs",
  input_pattern: "(.*)%.moon$",
  output_ext: ".lua"

  show_timings: os.getenv "TIME"

  diff: {
    tool: "git diff --no-index --color" --color-words"
    filter: (str) ->
      -- strip the first four lines
      table.concat [l for l in *([line for line in str\gmatch("[^\n]+")])[5,]], "\n"
  }
}

timings = {}

gettime = nil

pcall ->
  require "socket"
  gettime = socket.gettime

gettime or= os.clock

benchmark = (fn) ->
  if gettime
    start = gettime!
    res = {fn!}
    gettime! - start, unpack res
  else
    nil, fn!

read_all = (fname) ->
  if f = io.open(fname, "r")
    with f\read "*a"
      f\close!

diff_file = (a_fname, b_fname) ->
  out = io.popen(options.diff.tool .. " ".. a_fname .. " " .. b_fname, "r")\read "*a"
  if options.diff.filter
    out = options.diff.filter out
  out

diff_str = (expected, got) ->
  a_tmp = os.tmpname! .. ".expected"
  b_tmp = os.tmpname! .. ".got"

  with io.open(a_tmp, "w")
    \write expected
    \close!

  with io.open(b_tmp, "w")
    \write got
    \close!

  with diff_file a_tmp, b_tmp
    os.remove a_tmp
    os.remove b_tmp

string_assert = (expected, got) ->
  if expected != got
    diff = diff_str expected, got
    error "string equality assert failed" if os.getenv "HIDE_DIFF"
    error "string equality assert failed:\n" .. diff

input_fname = (base) ->
  options.in_dir .. "/" .. base .. ".moon"

output_fname = (base) ->
  options.out_dir .. "/" .. base .. options.output_ext

inputs = for file in lfs.dir options.in_dir
  with match = file\match options.input_pattern
    continue unless match

table.sort inputs

describe "input tests", ->
  local parse, compile

  with_dev ->
    parse = require "moonscript.parse"
    compile = require "moonscript.compile"
  
  for name in *inputs
    input = input_fname name
    it input .. " #input", ->
      file_str = read_all input_fname name

      parse_time, tree, err = benchmark -> parse.string file_str
      error err if err
      compile_time, code, err, pos = benchmark -> compile.tree tree
      error compile.format_error err, pos, file_str unless code

      table.insert timings, {name, parse_time, compile_time}

      if os.getenv "BUILD"
        with io.open output_fname(name), "w"
          \write code
          \close!
      else
        expected_str = read_all output_fname name
        error "Test not built: " .. input_fname(name) unless expected_str

        string_assert expected_str, code

      nil

  if options.show_timings
    teardown ->
      format_time = (sec) -> ("%.3fms")\format(sec*1000)
      col_width = math.max unpack [#t[1] for t in *timings]

      print "\nTimings:"
      total_parse, total_compile = 0, 0
      for tuple in *timings
        name, parse_time, compile_time = unpack tuple
        name = name .. (" ")\rep col_width - #name
        total_parse += parse_time
        total_compile += compile_time

        print " * " .. name,
          "p: " .. format_time(parse_time),
          "c: " .. format_time(compile_time)

      print "\nTotal:"
      print "    parse:", format_time total_parse
      print "  compile:", format_time total_compile

