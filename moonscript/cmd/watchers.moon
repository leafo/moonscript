remove_dupes = (list, key_fn) ->
  seen = {}
  return for item in *list
    key = if key_fn then key_fn item else item
    continue if seen[key]
    seen[key] = true
    item

plural = (count, word) ->
  "#{count} #{word}#{count == 1 and "" or "s"}"

-- files is a list of tuples, {source, target}
class Watcher
  start_msg: "Starting watch loop (Ctrl-C to exit)"
  new: (@file_list) =>

  print_start: (mode, misc) =>
    io.stderr\write "#{@start_msg} with #{mode} [#{misc}]\n"

class InotifyWacher extends Watcher
  @available: =>
    pcall -> require "inotify"

  get_dirs: =>
    import parse_dir from require "moonscript.cmd.moonc"
    dirs = for {file_path} in *@file_list
      dir = parse_dir file_path
      dir = "./" if dir == ""
      dir

    remove_dupes dirs

  -- creates an iterator that yields a file every time it's updated
  -- TODO: detect when new files are added to directories
  each_update: =>
    coroutine.wrap ->
      dirs = @get_dirs!

      @print_start "inotify", plural #dirs, "dir"

      wd_table = {}

      inotify = require "inotify"
      handle = inotify.init!

      for dir in *dirs
        wd = handle\addwatch dir, inotify.IN_CLOSE_WRITE, inotify.IN_MOVED_TO
        wd_table[wd] = dir

      while true
        events = handle\read!
        break unless events -- error?

        for ev in *events
          fname = ev.name
          continue unless fname\match "%.moon$"
          dir = wd_table[ev.wd]
          fname = dir .. fname if dir != "./"

          -- TODO: check to make sure the file was in the original set
          coroutine.yield fname

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

  each_update: =>
    coroutine.wrap ->
      lfs = require "lfs"
      sleep = @get_sleep_func!

      @print_start "polling", plural #@file_list, "files"
      mod_time = {}

      while true
        for {file} in *@file_list
          time = lfs.attributes file, "modification"
          unless time -- file no longer exists
            mod_time[file] = nil
            continue

          unless mod_time[file] -- file time scanned
            mod_time[file] = time
            continue

          if time > mod_time[file]
            mod_time[file] = time
            coroutine.yield file

        sleep @polling_rate

{:Watcher, :SleepWatcher, :InotifyWacher}
