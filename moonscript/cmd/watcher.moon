remove_dupes = (list, key_fn) ->
  seen = {}
  return for item in *list
    key = if key_fn then key_fn item else item
    continue if seen[key]
    seen[key] = true
    item

-- files is a list of tuples, {source, target}
class Watcher
  new: (@file_list) =>


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

class SleepWatcher

{:Watcher, :SleepWatcher, :InotifyWacher}
