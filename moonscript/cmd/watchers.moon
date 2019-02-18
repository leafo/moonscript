lfs = require "lfs"
moonc = require "moonscript.cmd.moonc"
import unpack from require "moonscript.util"
import process_filesystem_tree from moonc
import iterate_path, parse_dir, parse_subtree, parse_root, dirsep, normalize_dir, normalize_path from require "moonscript.cmd.path_handling"

remove_dupes = (list, key_fn) ->
  seen = {}
  return for item in *list
    key = if key_fn then key_fn item else item
    continue if seen[key]
    seen[key] = true
    item

plural = (count, word) ->
  "#{count} #{word}#{count == 1 and "" or "s"}"

-- input_paths is the raw list of files and directories passed to moonc
-- output_to is the folder specified by --output-to, or nil if not set
class Watcher
  start_msg: "Starting watch loop (Ctrl-C to exit)"
  new: (@output_to, @initial_paths, @prefix_map) =>
    -- Track files given in initial_paths, as unlike other files they will be
    -- compiled even if they do not have the .moon extension
    @initial_files = {}
    for path_tuple in *@initial_paths
      {path, path_type} = path_tuple
      if path_type == "file"
        @initial_files[normalize_path path] = true

  output_for: (path, path_type) =>
    moonc.output_for @output_to, @prefix_map, path, path_type

  print_start: (mode, misc) =>
    io.stderr\write "#{@start_msg} with #{mode} [#{misc}]\n"

  -- We only compile .moon files, and non-.moon files given directly on the CLI
  valid_moon_file: (file) =>
    file = normalize_path file
    return file\match("%.moon$") != nil or @initial_files[file] != nil

class InotifyWatcher extends Watcher
  @available: =>
    pcall -> require "inotify"

  new: (input_paths, output_to, prefix_map) =>
    super input_paths, output_to, prefix_map

    -- Maps wd handles to path tuples of watched paths
    @wd_map = {}
    -- Maps watched paths (not path tuples) to wd handles
    @path_map = {}
    -- Maps all 'seen' (not only those directly watched) paths to path type;
    -- needed in order to sanely delete 'orphaned' output paths
    @path_type_map = {}

    @inotify = require "inotify"
    @file_event_types = {
      @inotify.IN_CLOSE_WRITE,
      @inotify.IN_MOVE_SELF,
      @inotify.IN_DELETE_SELF,
    }
    @dir_event_types = {
      @inotify.IN_CLOSE_WRITE,
      @inotify.IN_MOVE_SELF,
      @inotify.IN_DELETE_SELF,
      @inotify.IN_CREATE,
      @inotify.IN_MOVED_TO,
      @inotify.IN_DELETE,
    }

    @handle = @inotify.init!

  -- Creates an iterator that yields an 'event tuple', with the specific
  -- structure depending on the type of event.
  -- Event types are "changedfile", for new/modified Moonscript files, and
  -- "removed", for a previously-seen Moonscript file being deleted.
  -- {"changedfile", source_file, target_file}
  -- {"removed", source_path, target_path, path_type}
  each_update: =>
    @print_start "inotify", (plural #@initial_paths, "path")
    coroutine.wrap ->
      @register_initial_watchers!
      -- Wait for & process events
      while true
        events, err_msg, err_no = @handle\read!
        if events == nil
          error "Error reading events from inotify handle, errno #{err_no}, message: #{err_msg}"

        for ev in *events
          @handle_event ev

  register_initial_watchers: () =>
    -- Register watchers for initial set of files and directories. Newly
    -- created subdirectories will get watchers added dynamically.
    for path_tuple in *@initial_paths
      {path, path_type} = path_tuple
      if path_type == "file"
        @register_watcher path, path_type, @file_event_types
      else
        @register_recursive_watchers path

  register_watcher: (path, path_type, events) =>
    -- We must guard against duplicate registrations due to a race condition:
    -- 1. New subdirectory is created or moved into place, event A is fired on
    --    its parent
    -- 2. We process event A and add a watcher
    -- 3. Before we finish recursively scanning the new subdirectory for
    --    further directories to register, a new sub-subdirectory X is created,
    --    and an event B is thus triggered on the subdirectory
    -- 4. We finish adding new subchildren, including the one created mid-scan,
    --    X
    -- 4. When event B gets processed, it will trigger a duplicate registration
    --    for sub-subdirectory X
    unless @path_map[path]
      wd = @handle\addwatch path, unpack events
      @wd_map[wd] = {path, path_type}
      @path_map[path] = wd
      @seen_path_type path, path_type
      if path_type == "file"
        -- Initial compile
        coroutine.yield {"changedfile", path, (@output_for path, path_type)}

  register_recursive_watchers: (path) =>
    directory_cb = (directory_path) ->
      @register_watcher directory_path, "directory", @dir_event_types
    file_cb = (file_path) ->
      if @valid_moon_file file_path
        @seen_path_type file_path, "file"
        coroutine.yield {"changedfile", file_path, (@output_for file_path, "file")}
    -- Handles recursively traversing the directory tree starting at path,
    -- calling the provided callbacks for children along the way (does
    -- pre-order traversal based on whatever ordering lfs.dir() uses)
    process_filesystem_tree path, directory_cb, file_cb

  handle_event: (ev) =>
    path_tuple = @wd_map[ev.wd]
    unless path_tuple
      -- It's possible to get events for paths after they have been deleted and
      -- unregistered from the wd_map; we just skip to the next event in this
      -- case.
      return
    {path, path_type} = path_tuple
    is_dir = path_type == 'directory'

    switch ev.mask
      when @inotify.IN_CLOSE_WRITE -- On both files and dirs
        -- A file has been created or modified, spit out a {target, output}
        -- tuple.

        if is_dir
          subpath = path .. ev.name
          subpath_type = lfs.attributes subpath, "mode"
          if subpath_type == "file" and @valid_moon_file subpath
            coroutine.yield {"changedfile", subpath, (@output_for subpath, subpath_type)}
        else
          coroutine.yield {"changedfile", path, (@output_for path, path_type)}


      when @inotify.IN_DELETE_SELF, @inotify.IN_MOVE_SELF -- On both files and dirs
        -- Remove the watch - TODO handle errors from rmwatch?
        @handle\rmwatch ev.wd
        @wd_map[ev.wd] = nil
        @path_map[path] = nil
        @path_type_map[path] = nil

        coroutine.yield {"removed", path, (@output_for path, path_type), path_type}

      when @inotify.IN_DELETE, @inotify.IN_MOVED_TO -- On dirs only
        subpath = path .. ev.name
        -- The path type can't be looked up directly, because the path no
        -- longer exists, so we check our list of 'seen' paths in @path_map
        subpath_type = @path_type_map[subpath]

        @path_type_map[subpath] = nil
        coroutine.yield {"removed", subpath, (@output_for subpath, subpath_type), subpath_type}

      when @inotify.IN_CREATE -- On dirs only
        subpath = path .. ev.name
        subpath_type = lfs.attributes subpath, "mode"
        if subpath_type == "directory"
          -- Scan the new subdirectory for any subdirectories of its own,
          -- register those, and compile any valid new paths
          @register_recursive_watchers normalize_dir subpath
        else
          -- We don't need to do much for newly-created files, because they
          -- also generate an IN_CLOSE_WRITE event which will potentially
          -- yielding for them. We could also handle new directories off of
          -- IN_CLOSE_WRITE, but it makes a bit more sense to do it on
          -- IN_CREATE.
          if @valid_moon_file subpath
            @seen_path_type subpath, subpath_type

  seen_path_type: (path, path_type) =>
    path = normalize_path path
    unless @path_type_map[path]
      @path_type_map[path] = path_type


class SleepWatcher extends Watcher
  polling_rate: 1.0

  -- the windows mooonscript binaries provide their own sleep function
  get_sleep_func: =>
    local sleep

    pcall ->
      sleep = require("socket").sleep

    -- TODO: this is also loading moonloader, which isn't intentional
    sleep or= require("moonscript")._sleep
    error "Missing sleep function; install LuaSocket" unless sleep
    sleep

  new: (input_paths, output_to, prefix_map) =>
    super input_paths, output_to, prefix_map

    @sleep = @get_sleep_func!

    -- Maps seen paths to their last-seen modification time
    @mod_time = {}
    -- Maps seen paths to path type; needed in order to sanely delete
    -- 'orphaned' output paths
    @path_type_map = {}

    for path_tuple in *@initial_paths
      {path, path_type} = path_tuple
      @path_type_map[path] = path_type

  each_update: =>
    @print_start "polling", (plural #@initial_paths, "path")

    coroutine.wrap ->
      while true
        @scan_path_times!
        @remove_missing_paths!
        @.sleep @polling_rate

  -- Scan all the given files and directories, recursively.
  -- The callbacks given to process_filesystem_tree may call coroutine.yeidl(),
  -- so keep in mind that calls to this should be done within a coroutine.
  scan_path_times: () =>
    for path_tuple in *@initial_paths
      {path, path_type} = path_tuple
      is_dir = path_type == 'directory'

      unless is_dir
        @process_file_time path
      else
        -- Run check for each subfile
        directory_cb = (directory_path) ->
          @process_directory_time directory_path
        file_cb = (file_path) ->
          @process_file_time file_path
        process_filesystem_tree path, directory_cb, file_cb

  process_file_time: (file) =>
    time = lfs.attributes file, "modification"
    return unless time -- file no longer exists
    return unless @valid_moon_file file

    output = @output_for file, 'file'
    unless @mod_time[file] -- new file, add timestamp, do initial build
      @mod_time[file] = time
      @path_type_map[file] = 'file'
      coroutine.yield {"changedfile", file, output}
    elseif time != @mod_time[file] -- update timestamp and trigger build
      -- != instead of > because the user could have e.g. replaced the file
      -- with a backed-up copy using a utility that sets modification time
      @mod_time[file] = time
      coroutine.yield {"changedfile", file, output}

  process_directory_time: (directory) =>
    time = lfs.attributes directory, "modification"
    unless time -- folder no longer exists
      return

    directory = normalize_dir directory
    unless @mod_time[directory]
      -- new directory, register in path map for deletion tracking
      @path_type_map[directory] = 'directory'

  -- Check previously-registered paths for any that may have been deleted, and
  -- delete the corresponding output paths.
  remove_missing_paths: () =>
    for path, path_type in pairs @path_type_map
      time = lfs.attributes path, "modification"
      -- Skip if it still exists
      continue if time

      -- Unregister the deleted path
      @path_type_map[path] = nil
      @mod_time[path] = nil

      coroutine.yield {"removed", path, (@output_for path, path_type), path_type}

{:Watcher, :SleepWatcher, :InotifyWatcher}
