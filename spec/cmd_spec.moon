
moonc = require "moonscript.cmd.moonc"

-- TODO: add specs for windows equivalents

describe "moonc", ->
  same = (fn, a, b)->
    assert.same b, fn a

  it "should normalize dir", ->
    same moonc.normalize_dir, "hello/world/", "hello/world/"
    same moonc.normalize_dir, "hello/world//", "hello/world/"
    same moonc.normalize_dir, "", "/" -- wrong
    same moonc.normalize_dir, "hello", "hello/"


  it "should parse dir", ->
    same moonc.parse_dir, "/hello/world/file", "/hello/world/"
    same moonc.parse_dir, "/hello/world/", "/hello/world/"
    same moonc.parse_dir, "world", ""
    same moonc.parse_dir, "", ""

  it "should parse file", ->
    same moonc.parse_file, "/hello/world/file", "file"
    same moonc.parse_file, "/hello/world/", ""
    same moonc.parse_file, "world", "world"
    same moonc.parse_file, "", ""

  it "convert path", ->
    same moonc.convert_path, "test.moon", "test.lua"
    same moonc.convert_path, "/hello/file.moon", "/hello/file.lua"
    same moonc.convert_path, "/hello/world/file", "/hello/world/file.lua"

  it "chould compile file text", ->
    assert.same {
      [[return print('hello')]]
    }, {
      moonc.compile_file_text "print'hello'", "test.moon"
    }

  describe "stubbed lfs", ->
    local dirs

    before_each ->
      dirs = {}
      package.loaded.lfs = nil
      package.loaded["moonscript.cmd.moonc"] = nil

      package.loaded.lfs = {
        mkdir: (dir) -> table.insert dirs, dir
        attributes: -> "directory"
      }

      moonc = require "moonscript.cmd.moonc"

    after_each ->
      package.loaded.lfs = nil
      package.loaded["moonscript.cmd.moonc"] = nil
      moonc = require "moonscript.cmd.moonc"

    it "should make directory", ->
      moonc.mkdir "hello/world/directory"
      assert.same {
        "hello"
        "hello/world"
        "hello/world/directory"
      }, dirs

