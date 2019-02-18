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

        output_to, _cli_paths, prefix_map = moonc.parse_cli_paths {direct_file, "foo", "foo_exclusive/"}, "nak"
        test_output_for = (path, path_type) ->
          moonc.output_for output_to, prefix_map, path, path_type

        assert.same "nak/bar.lua", (test_output_for direct_file, "file")
        assert.same "nak/foo/baz.lua", (test_output_for inclusive_subfile, "file")
        assert.same "nak/baz.lua", (test_output_for exclusive_subfile, "file")
        assert.same "nak/foo/", (test_output_for inclusive_dir, "directory")
        assert.same "nak/", (test_output_for exclusive_dir, "directory")

describe "watcher", ->
  local watchers, moonc, lfs, os_remove, fs_root, stubs
  -- TODO why doesn't this declaration work if split over two lines, following a ,?
  local direct_file, direct_file_sans_ext, inclusive_dir, exclusive_dir, inclusive_subfile, inclusive_nonmoon_subfile, exclusive_subfile, output_to, test_watcher, all_valid_files, all_files, all_dirs, subdir, valid_file_count, input_paths, prefix_map

  dev_loaded = with_dev ->
    moonc = require "moonscript.cmd.moonc"
    watchers = require "moonscript.cmd.watchers"

  -- Sets up filesystem stubs so we don't need to test against actual files
  -- and directories
  before_each ->
    package.loaded.lfs = nil
    os_remove = package.loaded.os_remove
    package.loaded.os.remove = nil
    dev_loaded["moonscript.cmd.moonc"] = nil
    dev_loaded["moonscript.cmd.watchers"] = nil

    import create_io_stubs from require "spec.fs_stubs"
    {:stubs, :fs_root} = create_io_stubs!
    {lfs: stub_lfs, os: stub_os} = stubs
    package.loaded.lfs = stub_lfs
    package.loaded.os.remove = stub_os.remove

    moonc = require "moonscript.cmd.moonc"
    watchers = require "moonscript.cmd.watchers"
    lfs = package.loaded.lfs

    -- Setup 'filesystem' to use for the tests
    direct_file = "bar.moon"
    direct_file_sans_ext = "scriptfile"
    inclusive_dir = "foo/"
    subdir = "foo/sub"
    exclusive_dir = "foo_exclusive/"
    inclusive_subfile = "foo/baz.moon"
    inclusive_nonmoon_subfile = "foo/not_a_moon_file"
    exclusive_subfile = "foo_exclusive/baz.moon"
    all_valid_files = {direct_file, direct_file_sans_ext, inclusive_subfile,
      exclusive_subfile} -- inclusive_nonmoon_subfile is not valid
    all_files = {direct_file, direct_file_sans_ext, inclusive_subfile,
      inclusive_nonmoon_subfile, exclusive_subfile}
    all_dirs = {inclusive_dir, subdir, exclusive_dir}

    for dir in *all_dirs
      lfs.mkdir dir

    for file in *all_files
      lfs.touch file

    output_to, input_paths, prefix_map = moonc.parse_cli_paths {
        "bar.moon", "scriptfile", "foo", "foo_exclusive/"
      }, "nak"

  after_each ->
    package.loaded.lfs = nil
    package.loaded.os.remove = os_remove
    dev_loaded["moonscript.cmd.watchers"] = nil

  describe "polling watcher", ->
    before_each ->
      -- Stub sleep(); it's not actually called during the testing but needs to
      -- be there for the import in SleepWatcher.new()
      package.loaded.socket =
        sleep: () -> nil
      test_watcher = watchers.SleepWatcher output_to, input_paths, prefix_map

    after_each ->
      package.loaded.socket = nil

    describe "process_file_time", ->
      local test_process
      before_each ->
        test_process = (path) ->
          co = coroutine.wrap test_watcher\process_file_time
          return co path

      assert_expected_output_for = (file) ->
        test_ret = test_process file
        assert.not.Nil test_ret
        {event_type, path, output} = test_ret
        assert.are.same "changedfile", event_type
        assert.are.same (test_watcher\output_for file, "file"), (output)
        assert.are.same file, path

      it "yields for new files", ->
        for file in *all_valid_files
          assert_expected_output_for file

      it "does not yield for old files without a change", ->
        -- Clear intial yield
        test_process direct_file

        assert.is.Nil test_process direct_file

      it "yields for old files with a change", ->
        -- Clear intial yield
        test_process direct_file

        -- Bump the modification time; +5 because the granularity is only 1
        -- second, and 1 second likely has not passed since the before_each()
        -- call created the file
        lfs.touch direct_file, nil, os.time! + 5

        assert_expected_output_for direct_file

      it "does not yield for non-existent files", ->
        assert.is.Nil test_process "not a present file"

      it "does not yield for non-.moon files in watched directories", ->
        assert.is.Nil test_process inclusive_nonmoon_subfile

      it "does yield for non-.moon files watched directly", ->
        assert_expected_output_for direct_file_sans_ext

    describe "scan_path_times", ->
      it "initially yields once per valid file", ->
        co_scan = coroutine.wrap test_watcher\scan_path_times

        for i = 1, #all_valid_files
          ret = co_scan!
          {event_type, input, output} = ret
          assert.are.same "changedfile", event_type
          assert.is.not.Nil ret
        assert.is.Nil co_scan!

      it "later yields once per file modification", ->
        co_scan = coroutine.wrap test_watcher\scan_path_times
        -- Clear initial yields
        for i = 1, #all_valid_files
          co_scan!
        -- Update a file's timestamp
        lfs.touch direct_file, nil, os.time! + 5
        -- Make a new coroutine
        co_scan = coroutine.wrap test_watcher\scan_path_times

        {event_type, input_file, _output_file} = co_scan!

        -- We get the modified file back
        assert.are.same direct_file, input_file
        assert.are.same "changedfile", event_type
        -- And we don't get any further yields
        assert.is.Nil co_scan!

    describe "remove_missing_paths", ->
      path_handling = require "moonscript.cmd.path_handling"
      before_each ->
        -- Prime the system by ensuring the watcher has recorded all the times
        co_scan = coroutine.wrap test_watcher\scan_path_times
        while co_scan! -- clear initial yields
          nil

      remove_input_files = (files) ->
        for file in *files
          os.remove file
          assert.is.Nil lfs.attributes file, "mode"

      remove_all_input_dirs = () ->
        -- Reverse order, because children are listed after parents
        for i = #all_dirs, 1, -1
          dir = all_dirs[i]
          os.remove dir
          assert.is.Nil lfs.attributes dir, "mode"

      test_removal = (files_removed) ->
        removal_count = 0
        co = coroutine.wrap test_watcher\remove_missing_paths

        path_tuple = co!
        while path_tuple != nil
          {event_type, path, output, path_type} = path_tuple
          assert.are.same "removed", event_type
          files_removed[output] = true
          removal_count += 1
          path_tuple = co!

        return removal_count

      it "does not generate removal events for output paths that have existing input paths", ->
        files_removed = {}

        removal_count = test_removal files_removed

        assert.are.same 0, removal_count

      it "generates removal events for output files that been orphaned", ->
        remove_input_files all_valid_files
        files_removed = {}

        removal_count = test_removal files_removed
        assert.are.same #all_valid_files, removal_count
        for file in *all_valid_files
          output = test_watcher\output_for file, "file"
          assert.is_true files_removed[output]

      it "generates removal events for output directories that have been orphaned", ->
        remove_input_files all_files
        remove_all_input_dirs!
        files_removed = {}

        -- Worst-case could take two passes to remove the dirs, as it does not
        -- guarantee removing children before removing dirs
        removal_count = test_removal files_removed
        removal_count += test_removal files_removed

        assert.are.same #all_valid_files + #all_dirs, removal_count
        for dir in *all_dirs
          output = test_watcher\output_for dir, "directory"
          output = path_handling.normalize_dir output
          assert.is.True files_removed[output]

  describe "inotify watcher", ->
    local inotify, test_watcher
    before_each ->
      {inotify: stub_inotify} = stubs
      package.loaded.inotify = stub_inotify
      inotify = package.loaded.inotify
      test_watcher = watchers.InotifyWatcher output_to, input_paths, prefix_map

    after_each ->
      package.loaded.inotify = nil

    describe "register_watcher", ->
      local test_register
      before_each ->
        test_register = (path, path_type) ->
          co = coroutine.wrap test_watcher\register_watcher
          if path_type == "file"
            return co path, path_type, test_watcher.file_event_types
          elseif path_type == "directory"
            return co path, path_type, test_watcher.dir_event_types
          else error "Unrecognized type"

      it "yields if the path is a file", ->
        ret = test_register direct_file, "file"

        assert.is.not.Nil ret
        {event_type, path, output} = ret
        assert.are.same "changedfile", event_type
        assert.are.same direct_file, path
        assert.are.same (test_watcher\output_for direct_file, "file"), output

      it "does not yield if the path is a directory", ->
        ret = test_register inclusive_dir, "directory"

        assert.is.Nil ret

    describe "register_recursive_watchers", ->
      local test_register_recursive
      before_each ->
        test_register_recursive = (path) ->
          co = coroutine.wrap test_watcher\register_recursive_watchers
          return () -> co path, test_watcher.dir_event_types

      it "does not yield for non-.moon files", ->
        get_yield = test_register_recursive inclusive_dir
        path_tuple = get_yield!
        assert.is.not.Nil path_tuple

        while path_tuple
          {_event_type, path, output} = path_tuple
          assert.are.not.same inclusive_nonmoon_subfile, path
          path_tuple = get_yield!

      it "does one yield per valid file", ->
        get_yield = test_register_recursive inclusive_dir
        valid_subfiles = {inclusive_subfile}
        for i = 1, #valid_subfiles
          path_tuple = get_yield!
          assert.is.not.Nil path_tuple

    describe "register_initial_watchers", ->
      it "does not yield for non-.moon files in the tree", ->
        co = coroutine.wrap test_watcher\register_initial_watchers

        path_tuple = co!
        assert.is.not.Nil path_tuple
        while path_tuple
          {_event_type, path, output} = path_tuple
          assert.are.not.same inclusive_nonmoon_subfile, path
          path_tuple = co!

      it "does yield for non-.moon files given directly", ->
        yielded_scriptfile = false
        co = coroutine.wrap test_watcher\register_initial_watchers

        path_tuple = co!
        assert.is.not.Nil path_tuple
        while path_tuple
          {event_type, path, output} = path_tuple
          assert.are.same "changedfile", event_type
          if path == direct_file_sans_ext
            yielded_scriptfile = true
          path_tuple = co!

        assert yielded_scriptfile

    describe "handle_event", ->
      local test_handle_event
      path_handling = require "moonscript.cmd.path_handling"
      before_each ->
        -- Register initial watchers
        co = coroutine.wrap test_watcher\register_initial_watchers
        co_ret = co!
        while co_ret != nil
          co_ret = co!

        test_handle_event = coroutine.wrap () ->
          ev = test_watcher.handle\read!
          test_watcher\handle_event ev

      it "yields when directly watched files change", ->
        inotify.generate_test_event direct_file, inotify.IN_CLOSE_WRITE

        path_tuple = test_handle_event!

        assert.is.not.Nil path_tuple
        {event_type, path, output} = path_tuple
        assert.are.same "changedfile", event_type
        assert.are.same direct_file, path
        assert.are.same (test_watcher\output_for direct_file), output

      it "yields when files in watched directories change", ->
        inotify.generate_test_event inclusive_subfile, inotify.IN_CLOSE_WRITE

        path_tuple = test_handle_event!

        assert.is.not.Nil path_tuple
        {event_type, path, output} = path_tuple
        assert.are.same "changedfile", event_type
        assert.are.same inclusive_subfile, path
        assert.are.same (test_watcher\output_for inclusive_subfile), output

      it "yields for files in newly-created subdirectories of watched directories", ->
        new_subdir = "#{inclusive_dir}new_subdir"
        new_file = "#{new_subdir}/afile.moon"
        moonc.mkdir new_subdir
        lfs.touch new_file
        inotify.generate_test_event new_subdir, inotify.IN_CREATE

        path_tuple = test_handle_event!

        assert.is.not.Nil path_tuple
        {event_type, path, output} = path_tuple
        assert.are.same "changedfile", event_type
        assert.are.same new_file, path
        assert.are.same (test_watcher\output_for new_file), output

      it "removes orphaned output files", ->
        output_path = test_watcher\output_for inclusive_subfile, "file"
        inotify.generate_test_event inclusive_subfile, inotify.IN_DELETE

        path_tuple = test_handle_event!

        {event_type, path, output, path_type} = path_tuple
        assert.are.same "removed", event_type
        assert.are.same inclusive_subfile, path
        assert.are.same output_path, output
        assert.are.same "file", path_type

      it "removes orphaned output directories", ->
        output_path = test_watcher\output_for inclusive_dir, "directory"
        inotify.generate_test_event inclusive_dir, inotify.IN_DELETE_SELF

        path_tuple = test_handle_event!

        {event_type, path, output, path_type} = path_tuple
        assert.are.same "removed", event_type
        assert.are.same inclusive_dir, path
        assert.are.same output_path, output
        assert.are.same "directory", path_type
