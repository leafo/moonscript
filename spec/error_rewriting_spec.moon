
moonscript = require "moonscript.base"
errors = require "moonscript.errors"
util = require "moonscript.util"

import unindent from require "spec.helpers"

get_rewritten_line_no = (fname) ->
  fname = "spec/error_inputs/#{fname}.moon"
  chunk = moonscript.loadfile fname

  success, err = pcall chunk
  error "`#{fname}` is supposed to have runtime error!" if success

  source = tonumber err\match "^.-:(%d+):"

  line_table = assert require("moonscript.line_tables")["@#{fname}"], "missing line table"
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

describe "line map", ->
  import to_lua from require "moonscript.base"

  it "should create line table", ->
    moon_code = unindent [[
      print "hello world"
      if something
        print "cats"
    ]]

    lua_code, posmap = assert to_lua moon_code
    -- print util.debug_posmap(posmap, moon_code, lua_code)
    assert.same { 7, 29, 42, 27 }, posmap

  it "should create line table for multiline string", ->
    moon_code = unindent [[
      print "one"
      x = [==[
        one
        two
        thre
        yes
        no
      ]==]
      print "two"
    ]]

    lua_code, posmap = assert to_lua moon_code
    -- print util.debug_posmap(posmap, moon_code, lua_code)
    assert.same {[1]: 7, [2]: 19, [7]: 19, [8]: 63}, posmap


