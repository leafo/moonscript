-- Creates stubs for the subset of filesystem functionality needed/used by
-- tested functions. functions stubbed are from the lfs, os, and inotify
-- modules.
create_io_stubs = () ->
  path_handling = require "moonscript.cmd.path_handling"

  new_node = (mode, mtime=os.time!) ->
    if mode == "directory"
      return {
        :mode
        children: {}
        child_count: 0
        modification: mtime
      }
    else
      return {
        :mode
        modification: mtime
      }

  fs_root = new_node "directory"

  add_child = (fs_node, child_name, child_node) ->
    assert fs_node.mode == "directory"
    assert fs_node.children[child_name] == nil
    fs_node.children[child_name] = child_node
    fs_node.child_count += 1

  remove_child = (fs_node, child_name) ->
    assert fs_node.mode == "directory" and fs_node.child_count > 0
    child_node = fs_node.children[child_name]
    assert child_node != nil
    if child_node.mode == "directory"
      if child_node.child_count == 0
        fs_node.children[child_name] = nil
        fs_node.child_count -= 1
        return true
      else
        return nil, "Specified path is not empty", 2 -- TODO
    else
      fs_node.children[child_name] = nil
      fs_node.child_count -= 1
      return true

  traverse_entire_path = (filepath, current_node=fs_root) ->
    filepath = path_handling.normalize_path filepath
    for path_element in path_handling.iterate_path filepath
      if current_node.children != nil and current_node.mode == 'directory'
        if next_node = current_node.children[path_element]
          current_node = next_node
        else
          return nil, "No such path"
      else
        return nil, "Non-final element in path is a file"
    return current_node

  -- Returns the parent node and the name of the child
  traverse_parent = (filepath, current_node=fs_root) ->
    filepath = path_handling.normalize_path filepath
    path_elements = {}
    for path_element in path_handling.iterate_path filepath
      path_elements[#path_elements + 1] = path_element

    if #path_elements > 1
      for i = 1, #path_elements - 1
        path_element = path_elements[i]
        if next_node = current_node.children[path_element]
          if next_node.mode == 'directory' and next_node.children != nil
            current_node = next_node
          else
            return nil, "Non-final element in path is a file"
        else
          return nil, "No such path"
    return current_node, path_elements[#path_elements]

  lfs =
    attributes: (filepath, aname) ->
      fs_node, err_msg = traverse_entire_path filepath

      unless fs_node
        return nil, err_msg, 2

      return fs_node[aname]

    rmdir: (dirpath) ->
      parent_node, child_name = traverse_parent dirpath

      unless parent_node
        return nil, "No such directory", 2

      -- Remove the last node from its parent
      if target_node = parent_node.children[child_name]
        if target_node.mode == 'directory'
          return remove_child parent_node, child_name
        else
          return nil, "Specified path is not a directory", 2
      else
        return nil, "No such directory", 2

    mkdir: (dirpath) ->
      dirpath = path_handling.normalize_path dirpath
      parent_node, child_name = traverse_parent dirpath

      unless parent_node
        return nil, "No such directory", 2

      -- Add a new node to the parent node
      unless parent_node.children[child_name]
        child_node = new_node "directory"
        add_child parent_node, child_name, child_node
        return true
      else
        return nil, "Cannot create a directory with a name identical to an existing path", 2

    touch: (path, _atime, mtime=os.time!) ->
      parent_node, child_name = traverse_parent path

      file_name = path_handling.parse_file path
      calc_path = path\sub(1, #path - #file_name)

      unless parent_node
        return nil, "No such directory", 2

      if target_node = parent_node.children[child_name]
        -- Update modtime on existing node
        target_node.modification = mtime
      else
        child_node = new_node "file", mtime
        add_child parent_node, child_name, child_node
      return true

    dir: (path) ->
      dir_node, err_msg = traverse_entire_path path
      unless dir_node
        error err_msg
      if dir_node.mode != "directory"
        error "Not a directory"

      local name
      dir_obj =
        children: dir_node.children
        next: () =>
          name, _val = next @children, name
          return name
        close: () -> nil
      iter = (dir_obj) -> dir_obj\next!
      return iter, dir_obj

  os =
    remove: (path) ->
      parent_node, child_name = traverse_parent path

      unless parent_node
        return nil, "No such file or directory", 2

      -- Remove the last node from its parent
      if parent_node.children[child_name]
        return remove_child parent_node, child_name
      else
        return nil, "No such file or directory", 2

  local inotify
  event_queue =
    start: 1
    end: 1
  wd_list =
    n: 1
  wds_by_path = {}
  inotify =
    init: () ->
      return {
        read: () =>
          if event_queue.start != event_queue.end
            ev = event_queue[event_queue.start]
            event_queue[event_queue.start] = nil
            event_queue.start += 1
            return ev
          else
            return nil, "inotify handle.read! called with no test events queued", -1
        addwatch: (path, ...) =>
          event_types = {}
          for _, ev_type in ipairs {...}
            event_types[ev_type] = true

          wd = wd_list.n
          wd_list.n += 1
          wd_list[wd] = {:path, :event_types}
          wds_by_path[path] = wd
          return wd
        rmwatch: (wd) =>
          wd_list[wd] = nil
          -- TODO error codes?
      }

    :event_queue
    generate_test_event: (path, ev_type) ->
      wd = if wds_by_path[path]
        -- Direct watcher
        wds_by_path[path]
      else
        -- Parent watcher
        wds_by_path[path_handling.parse_dir path]
      unless wd and wd_list[wd]
        error "Attempted to generate test event for unwatched path #{path}"
      unless wd_list[wd].event_types[ev_type]
        error "Attempted to generate test event type #{ev_type} for watcher that does not watch that type"

      event =
        :wd
        mask: ev_type
        name: path_handling.parse_file path
      event_queue[event_queue.end] = event
      event_queue.end += 1

    IN_CLOSE_WRITE: 1
    IN_MOVE_SELF: 2
    IN_DELETE_SELF: 3
    IN_MOVED_TO: 4
    IN_DELETE: 5
    IN_CREATE: 6

  stubs = { :lfs, :os, :inotify }

  return { :stubs, :fs_root, :traverse_entire_path, :traverse_parent, :new_node, :add_child, :remove_child }

{ :create_io_stubs }
