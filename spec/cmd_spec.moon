import with_dev from require "spec.helpers"

-- TODO: add specs for windows equivalents

describe "path_handling", ->
  local path_handling

  dev_loaded = with_dev ->
    path_handling = require "moonscript.cmd.path_handling"

  same = (fn, a, b) ->
    assert.same b, fn a

  it "should normalize dir", ->
    same path_handling.normalize_dir, "hello/world/", "hello/world/"
    same path_handling.normalize_dir, "/hello/world/", "/hello/world/"
    same path_handling.normalize_dir, "hello/world//", "hello/world/"
    same path_handling.normalize_dir, "/hello/world//", "/hello/world/"
    same path_handling.normalize_dir, "hello//world//", "hello/world/"
    same path_handling.normalize_dir, "/hello//world//", "/hello/world/"
    same path_handling.normalize_dir, "", ""
    same path_handling.normalize_dir, "/", "/"
    same path_handling.normalize_dir, "hello", "hello/"
    same path_handling.normalize_dir, "/hello", "/hello/"

  it "should parse dir", ->
    same path_handling.parse_dir, "/hello/world/file", "/hello/world/"
    same path_handling.parse_dir, "/hello/world/", "/hello/world/"
    same path_handling.parse_dir, "world", ""
    same path_handling.parse_dir, "", ""

  it "should parse file", ->
    same path_handling.parse_file, "/hello/world/file", "file"
    same path_handling.parse_file, "/hello/world/", ""
    same path_handling.parse_file, "world", "world"
    same path_handling.parse_file, "", ""

  it "convert path", ->
    same path_handling.convert_path, "test.moon", "test.lua"
    same path_handling.convert_path, "/hello/file.moon", "/hello/file.lua"
    same path_handling.convert_path, "/hello/world/file", "/hello/world/file.lua"

  it "iterates paths", ->
    single = {"foo"}
    single_path = "foo"
    nested = {"foo", "bar"}
    nested_path = "foo/bar"
    nested_file = {"foo", "bar.baz"}
    nested_file_path = "foo/bar.baz"

    same_iterated_path = (path, comparison_tbl) ->
      i = 0
      for path_element in path_handling.iterate_path(path)
        i += 1
        assert.same comparison_tbl[i], path_element
      assert.same #comparison_tbl, i

    same_iterated_path single_path, single
    same_iterated_path nested_path, nested
    same_iterated_path nested_file_path, nested_file

describe "moonc", ->
  local moonc, path_handling

  dev_loaded = with_dev ->
    path_handling = require "moonscript.cmd.path_handling"
    moonc = require "moonscript.cmd.moonc"

  same = (fn, a, b) ->
    assert.same b, fn a

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

