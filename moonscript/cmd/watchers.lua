local lfs = require("lfs")
local moonc = require("moonscript.cmd.moonc")
local unpack
unpack = require("moonscript.util").unpack
local process_filesystem_tree
process_filesystem_tree = moonc.process_filesystem_tree
local iterate_path, parse_dir, parse_subtree, parse_root, dirsep, normalize_dir, normalize_path
do
  local _obj_0 = require("moonscript.cmd.path_handling")
  iterate_path, parse_dir, parse_subtree, parse_root, dirsep, normalize_dir, normalize_path = _obj_0.iterate_path, _obj_0.parse_dir, _obj_0.parse_subtree, _obj_0.parse_root, _obj_0.dirsep, _obj_0.normalize_dir, _obj_0.normalize_path
end
local remove_dupes
remove_dupes = function(list, key_fn)
  local seen = { }
  return (function()
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #list do
      local _continue_0 = false
      repeat
        local item = list[_index_0]
        local key
        if key_fn then
          key = key_fn(item)
        else
          key = item
        end
        if seen[key] then
          _continue_0 = true
          break
        end
        seen[key] = true
        local _value_0 = item
        _accum_0[_len_0] = _value_0
        _len_0 = _len_0 + 1
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
    return _accum_0
  end)()
end
local plural
plural = function(count, word)
  return tostring(count) .. " " .. tostring(word) .. tostring(count == 1 and "" or "s")
end
local Watcher
do
  local _class_0
  local _base_0 = {
    start_msg = "Starting watch loop (Ctrl-C to exit)",
    output_for = function(self, path, path_type)
      return moonc.output_for(self.output_to, self.prefix_map, path, path_type)
    end,
    print_start = function(self, mode, misc)
      return io.stderr:write(tostring(self.start_msg) .. " with " .. tostring(mode) .. " [" .. tostring(misc) .. "]\n")
    end,
    valid_moon_file = function(self, file)
      file = normalize_path(file)
      return file:match("%.moon$") ~= nil or self.initial_files[file] ~= nil
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, output_to, initial_paths, prefix_map)
      self.output_to, self.initial_paths, self.prefix_map = output_to, initial_paths, prefix_map
      self.initial_files = { }
      local _list_0 = self.initial_paths
      for _index_0 = 1, #_list_0 do
        local path_tuple = _list_0[_index_0]
        local path, path_type
        path, path_type = path_tuple[1], path_tuple[2]
        if path_type == "file" then
          self.initial_files[normalize_path(path)] = true
        end
      end
    end,
    __base = _base_0,
    __name = "Watcher"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Watcher = _class_0
end
local InotifyWatcher
do
  local _class_0
  local _parent_0 = Watcher
  local _base_0 = {
    each_update = function(self)
      self:print_start("inotify", (plural(#self.initial_paths, "path")))
      return coroutine.wrap(function()
        self:register_initial_watchers()
        while true do
          local events, err_msg, err_no = self.handle:read()
          if events == nil then
            error("Error reading events from inotify handle, errno " .. tostring(err_no) .. ", message: " .. tostring(err_msg))
          end
          for _index_0 = 1, #events do
            local ev = events[_index_0]
            self:handle_event(ev)
          end
        end
      end)
    end,
    register_initial_watchers = function(self)
      local _list_0 = self.initial_paths
      for _index_0 = 1, #_list_0 do
        local path_tuple = _list_0[_index_0]
        local path, path_type
        path, path_type = path_tuple[1], path_tuple[2]
        if path_type == "file" then
          self:register_watcher(path, path_type, self.file_event_types)
        else
          self:register_recursive_watchers(path)
        end
      end
    end,
    register_watcher = function(self, path, path_type, events)
      if not (self.path_map[path]) then
        local wd = self.handle:addwatch(path, unpack(events))
        self.wd_map[wd] = {
          path,
          path_type
        }
        self.path_map[path] = wd
        self:seen_path_type(path, path_type)
        if path_type == "file" then
          return coroutine.yield({
            "changedfile",
            path,
            (self:output_for(path, path_type))
          })
        end
      end
    end,
    register_recursive_watchers = function(self, path)
      local directory_cb
      directory_cb = function(directory_path)
        return self:register_watcher(directory_path, "directory", self.dir_event_types)
      end
      local file_cb
      file_cb = function(file_path)
        if self:valid_moon_file(file_path) then
          self:seen_path_type(file_path, "file")
          return coroutine.yield({
            "changedfile",
            file_path,
            (self:output_for(file_path, "file"))
          })
        end
      end
      return process_filesystem_tree(path, directory_cb, file_cb)
    end,
    handle_event = function(self, ev)
      local path_tuple = self.wd_map[ev.wd]
      if not (path_tuple) then
        return 
      end
      local path, path_type
      path, path_type = path_tuple[1], path_tuple[2]
      local is_dir = path_type == 'directory'
      local _exp_0 = ev.mask
      if self.inotify.IN_CLOSE_WRITE == _exp_0 then
        if is_dir then
          local subpath = path .. ev.name
          local subpath_type = lfs.attributes(subpath, "mode")
          if subpath_type == "file" and self:valid_moon_file(subpath) then
            return coroutine.yield({
              "changedfile",
              subpath,
              (self:output_for(subpath, subpath_type))
            })
          end
        else
          return coroutine.yield({
            "changedfile",
            path,
            (self:output_for(path, path_type))
          })
        end
      elseif self.inotify.IN_DELETE_SELF == _exp_0 or self.inotify.IN_MOVE_SELF == _exp_0 then
        self.handle:rmwatch(ev.wd)
        self.wd_map[ev.wd] = nil
        self.path_map[path] = nil
        self.path_type_map[path] = nil
        return coroutine.yield({
          "removed",
          path,
          (self:output_for(path, path_type)),
          path_type
        })
      elseif self.inotify.IN_DELETE == _exp_0 or self.inotify.IN_MOVED_TO == _exp_0 then
        local subpath = path .. ev.name
        local subpath_type = self.path_type_map[subpath]
        self.path_type_map[subpath] = nil
        return coroutine.yield({
          "removed",
          subpath,
          (self:output_for(subpath, subpath_type)),
          subpath_type
        })
      elseif self.inotify.IN_CREATE == _exp_0 then
        local subpath = path .. ev.name
        local subpath_type = lfs.attributes(subpath, "mode")
        if subpath_type == "directory" then
          return self:register_recursive_watchers(normalize_dir(subpath))
        else
          if self:valid_moon_file(subpath) then
            return self:seen_path_type(subpath, subpath_type)
          end
        end
      end
    end,
    seen_path_type = function(self, path, path_type)
      path = normalize_path(path)
      if not (self.path_type_map[path]) then
        self.path_type_map[path] = path_type
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, input_paths, output_to, prefix_map)
      _class_0.__parent.__init(self, input_paths, output_to, prefix_map)
      self.wd_map = { }
      self.path_map = { }
      self.path_type_map = { }
      self.inotify = require("inotify")
      self.file_event_types = {
        self.inotify.IN_CLOSE_WRITE,
        self.inotify.IN_MOVE_SELF,
        self.inotify.IN_DELETE_SELF
      }
      self.dir_event_types = {
        self.inotify.IN_CLOSE_WRITE,
        self.inotify.IN_MOVE_SELF,
        self.inotify.IN_DELETE_SELF,
        self.inotify.IN_CREATE,
        self.inotify.IN_MOVED_TO,
        self.inotify.IN_DELETE
      }
      self.handle = self.inotify.init()
    end,
    __base = _base_0,
    __name = "InotifyWatcher",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.available = function(self)
    return pcall(function()
      return require("inotify")
    end)
  end
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  InotifyWatcher = _class_0
end
local SleepWatcher
do
  local _class_0
  local _parent_0 = Watcher
  local _base_0 = {
    polling_rate = 1.0,
    get_sleep_func = function(self)
      local sleep
      pcall(function()
        sleep = require("socket").sleep
      end)
      sleep = sleep or require("moonscript")._sleep
      if not (sleep) then
        error("Missing sleep function; install LuaSocket")
      end
      return sleep
    end,
    each_update = function(self)
      self:print_start("polling", (plural(#self.initial_paths, "path")))
      return coroutine.wrap(function()
        while true do
          self:scan_path_times()
          self:remove_missing_paths()
          self.sleep(self.polling_rate)
        end
      end)
    end,
    scan_path_times = function(self)
      local _list_0 = self.initial_paths
      for _index_0 = 1, #_list_0 do
        local path_tuple = _list_0[_index_0]
        local path, path_type
        path, path_type = path_tuple[1], path_tuple[2]
        local is_dir = path_type == 'directory'
        if not (is_dir) then
          self:process_file_time(path)
        else
          local directory_cb
          directory_cb = function(directory_path)
            return self:process_directory_time(directory_path)
          end
          local file_cb
          file_cb = function(file_path)
            return self:process_file_time(file_path)
          end
          process_filesystem_tree(path, directory_cb, file_cb)
        end
      end
    end,
    process_file_time = function(self, file)
      local time = lfs.attributes(file, "modification")
      if not (time) then
        return 
      end
      if not (self:valid_moon_file(file)) then
        return 
      end
      local output = self:output_for(file, 'file')
      if not (self.mod_time[file]) then
        self.mod_time[file] = time
        self.path_type_map[file] = 'file'
        return coroutine.yield({
          "changedfile",
          file,
          output
        })
      elseif time ~= self.mod_time[file] then
        self.mod_time[file] = time
        return coroutine.yield({
          "changedfile",
          file,
          output
        })
      end
    end,
    process_directory_time = function(self, directory)
      local time = lfs.attributes(directory, "modification")
      if not (time) then
        return 
      end
      directory = normalize_dir(directory)
      if not (self.mod_time[directory]) then
        self.path_type_map[directory] = 'directory'
      end
    end,
    remove_missing_paths = function(self)
      for path, path_type in pairs(self.path_type_map) do
        local _continue_0 = false
        repeat
          local time = lfs.attributes(path, "modification")
          if time then
            _continue_0 = true
            break
          end
          self.path_type_map[path] = nil
          self.mod_time[path] = nil
          coroutine.yield({
            "removed",
            path,
            (self:output_for(path, path_type)),
            path_type
          })
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, input_paths, output_to, prefix_map)
      _class_0.__parent.__init(self, input_paths, output_to, prefix_map)
      self.sleep = self:get_sleep_func()
      self.mod_time = { }
      self.path_type_map = { }
      local _list_0 = self.initial_paths
      for _index_0 = 1, #_list_0 do
        local path_tuple = _list_0[_index_0]
        local path, path_type
        path, path_type = path_tuple[1], path_tuple[2]
        self.path_type_map[path] = path_type
      end
    end,
    __base = _base_0,
    __name = "SleepWatcher",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  SleepWatcher = _class_0
end
return {
  Watcher = Watcher,
  SleepWatcher = SleepWatcher,
  InotifyWatcher = InotifyWatcher
}
