
import unindent, with_dev from require "spec.helpers"

describe "moonscript.errors", ->
  local moonscript, errors, util, to_lua

  -- with_dev ->
  moonscript = require "moonscript.base"
  errors = require "moonscript.errors"
  util = require "moonscript.util"

  {:to_lua} = moonscript

  get_rewritten_line_no = (fname) ->
    fname = "spec/error_inputs/#{fname}.moon"
    chunk = moonscript.loadfile fname

    success, err = pcall chunk
    error "`#{fname}` is supposed to have runtime error!" if success

    source = tonumber err\match "^.-:(%d+):"

    line_table = assert require("moonscript.line_tables")["@#{fname}"], "missing line table"
    errors.reverse_line_number fname, line_table, source, {}

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
    it "should create line table", ->
      moon_code = unindent [[
        print "hello world"
        if something
          print "cats"
      ]]

      lua_code, posmap = assert to_lua moon_code
      -- print util.debug_posmap(posmap, moon_code, lua_code)
      assert.same { 1, 23, 36, 21 }, posmap

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
      assert.same {[1]: 1, [2]: 13, [7]: 13, [8]: 57}, posmap

  describe "error reporting", ->
    it "should compile bad code twice", ->
      code, err = to_lua "{b=5}"
      assert.truthy err
      code, err2 = to_lua "{b=5}"
      assert.same err, err2
