
moonscript = require "moonscript.base"
errors = require "moonscript.errors"
util = require "moonscript.util"

get_rewritten_line_no = (fname) ->
  fname = "spec/error_inputs/#{fname}.moon"
  chunk = moonscript.loadfile fname

  success, err = pcall chunk
  error "`#{fname}` is supposed to have runtime error!" if success

  source = tonumber err\match "]:(%d+)"

  line_table = require("moonscript.line_tables")[fname]
  errors.reverse_line_number fname, line_table, source, {}


-- TODO: check entire stack trace
describe "error rewriting", ->
  tests = {
    "first": 24
    "second": 16
    "third": 11
  }

  for name, expected_no in pairs tests
    it "should rewrite line number", ->
      assert.same get_rewritten_line_no(name), expected_no

