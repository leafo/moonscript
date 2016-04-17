
import with_dev from require "spec.helpers"

-- TODO: add specs for windows equivalents

describe "moonc", ->
  local moonc

  dev_loaded = with_dev ->
    moonc = require "moonscript.cmd.moonc"

  same = (fn, a, b) ->
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

  it "calculate target", ->
    p = moonc.path_to_target

    assert.same "test.lua", p "test.moon"
    assert.same "hello/world.lua", p "hello/world.moon"
    assert.same "compiled/test.lua", p "test.moon", "compiled"

    assert.same "/home/leafo/test.lua", p "/home/leafo/test.moon"
    assert.same "compiled/test.lua", p "/home/leafo/test.moon", "compiled"
    assert.same "/compiled/test.lua", p "/home/leafo/test.moon", "/compiled/"

    assert.same "moonscript/hello.lua", p "moonscript/hello.moon", nil, "moonscript"
    assert.same "out/moonscript/hello.lua", p "moonscript/hello.moon", "out", "moonscript"

    assert.same "out/moonscript/package/hello.lua",
      p "moonscript/package/hello.moon", "out", "moonscript/"

    assert.same "/out/moonscript/package/hello.lua",
      p "/home/leafo/moonscript/package/hello.moon", "/out", "/home/leafo/moonscript"

  it "should compile file text", ->
    assert.same {
      [[return print('hello')]]
    }, {
      moonc.compile_file_text "print'hello'", fname: "test.moon"
    }

  describe "watcher", ->
    describe "inotify watcher", ->
      it "gets dirs", ->
        import InotifyWacher from require "moonscript.cmd.watchers"
        watcher = InotifyWacher {
          {"hello.moon", "hello.lua"}
          {"cool/no.moon", "cool/no.lua"}
        }

        assert.same {
          "./"
          "cool/"
        }, watcher\get_dirs!

  describe "parse args", ->
    it "parses spec", ->
      import parse_spec from require "moonscript.cmd.args"
      spec = parse_spec "lt:o:X"
      assert.same {
        X: {}
        o: {value: true}
        t: {value: true}
        l: {}
      }, spec

    it "parses arguments", ->
      import parse_arguments from require "moonscript.cmd.args"
      out, res = parse_arguments {
        "ga:p"
        print: "p"
      }, {"hello", "word", "-gap"}

      assert.same {
        g: true
        a: true
        p: true
      }, out

  describe "stubbed lfs", ->
    local dirs

    before_each ->
      dirs = {}
      package.loaded.lfs = nil
      dev_loaded["moonscript.cmd.moonc"] = nil

      package.loaded.lfs = {
        mkdir: (dir) -> table.insert dirs, dir
        attributes: -> "directory"
      }

      moonc = require "moonscript.cmd.moonc"

    after_each ->
      package.loaded.lfs = nil
      dev_loaded["moonscript.cmd.moonc"] = nil
      moonc = require "moonscript.cmd.moonc"

    it "should make directory", ->
      moonc.mkdir "hello/world/directory"
      assert.same {
        "hello"
        "hello/world"
        "hello/world/directory"
      }, dirs

