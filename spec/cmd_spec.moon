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

  it "should compile file text", ->
    assert.same {
      [[return print('hello')]]
    }, {
      moonc.compile_file_text "print'hello'", fname: "test.moon"
    }

  describe "watcher", ->
    describe "inotify watcher", ->
      it "gets dirs", ->
        import InotifyWatcher from require "moonscript.cmd.watchers"
        watcher = InotifyWatcher {
          {"hello.moon", "hello.lua"}
          {"cool/no.moon", "cool/no.lua"}
        }

        assert.same {
          "./"
          "cool/"
        }, watcher\get_dirs!

  describe "stubbed lfs", ->
    local lfs, os_remove

    before_each ->
      package.loaded.lfs = nil
      os_remove = package.loaded.os_remove
      package.loaded.os.remove = nil
      dev_loaded["moonscript.cmd.moonc"] = nil

      import create_io_stubs from require "spec.fs_stubs"
      {:stubs, :fs_root} = create_io_stubs!
      {lfs: stub_lfs, os: stub_os} = stubs
      package.loaded.lfs = stub_lfs
      package.loaded.os.remove = stub_os.remove

      moonc = require "moonscript.cmd.moonc"
      lfs = package.loaded.lfs

    after_each ->
      package.loaded.lfs = nil
      package.loaded.os.remove = os_remove
      dev_loaded["moonscript.cmd.moonc"] = nil
      moonc = require "moonscript.cmd.moonc"

    describe "mkdir", ->
      it "should make directory", ->
        dirs_in_path = {"hello", "world", "directory"}

        moonc.mkdir "hello/world/directory"

        path = ""
        for dir in *dirs_in_path
          path ..= dir .. "/"
          assert.are.same "directory", lfs.attributes(path, "mode")

    describe "process_filesystem_tree", ->
      it "runs callbacks for nodes in a filesystem tree", ->
        direct_file = "bar.moon"
        lfs.touch direct_file
        dir = "foo/"
        lfs.mkdir dir
        subdir = "foo/sub"
        lfs.mkdir subdir
        subfile = "foo/baz.moon"
        lfs.touch subfile
        another_dir = "nak/"
        lfs.mkdir another_dir
        another_subfile = "nak/baz.moon"
        lfs.touch another_subfile

        files = {}
        dirs = {}
        file_cb = (file) ->
          files[file] = true
        dir_cb = (dir) ->
          dirs[dir] = true
        moonc.process_filesystem_tree dir, dir_cb, file_cb

        assert dirs[(path_handling.normalize_dir dir)]
        assert dirs[(path_handling.normalize_dir subdir)]
        assert files[(path_handling.normalize_path subfile)]
        assert.is.Nil dirs[(path_handling.normalize_path another_dir)]
        assert.is.Nil files[(path_handling.normalize_path another_subfile)]

    describe "parse_cli_paths", ->
      it "errors if not given paths", ->
        test_parse = () -> moonc.parse_cli_paths nil, nil

        assert.has_error test_parse, "No paths specified"

      it "errors on missing paths", ->
        test_parse = () -> moonc.parse_cli_paths {"non_existent_path"}

        assert.error_matches test_parse, "Error code"

      it "accepts existing directories and files", ->
        lfs.mkdir "foo"
        lfs.touch "foo/bar"
        lfs.mkdir "baz"

        test_parse = () -> moonc.parse_cli_paths {"foo", "foo/bar", "baz"}

        assert.has.no.error test_parse

    describe "output_for", ->
      it "maps file output paths", ->
        direct_file = "bar.moon"
        lfs.touch direct_file
        dir = "foo/"
        lfs.mkdir dir
        subfile = "foo/baz.moon"
        lfs.touch subfile

        output_to, _cli_paths, prefix_map = moonc.parse_cli_paths {direct_file, "foo"}
        test_output_for = (path, path_type) ->
          moonc.output_for output_to, prefix_map, path, path_type

        assert.same "bar.lua", (test_output_for direct_file, "file")
        assert.same "foo/baz.lua", (test_output_for subfile, "file")
        assert.same "foo/", (test_output_for dir, "directory")

      it "maps file output paths with output-to set", ->
        direct_file = "bar.moon"
        lfs.touch direct_file
        inclusive_dir = "foo/"
        lfs.mkdir inclusive_dir
        exclusive_dir = "foo_exclusive/"
        lfs.mkdir exclusive_dir
        inclusive_subfile = "foo/baz.moon"
        lfs.touch inclusive_subfile
        exclusive_subfile = "foo_exclusive/baz.moon"
        lfs.touch exclusive_subfile

        output_to, cli_paths, prefix_map = moonc.parse_cli_paths {direct_file, "foo", "foo_exclusive/"}, "nak"
        test_output_for = (path, path_type) ->
          moonc.output_for output_to, prefix_map, path, path_type

        assert.same "nak/bar.lua", (test_output_for direct_file, "file")
        assert.same "nak/foo/baz.lua", (test_output_for inclusive_subfile, "file")
        assert.same "nak/baz.lua", (test_output_for exclusive_subfile, "file")
        assert.same "nak/foo/", (test_output_for inclusive_dir, "directory")
        assert.same "nak/", (test_output_for exclusive_dir, "directory")

