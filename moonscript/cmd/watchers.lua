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
    print_start = function(self, mode, misc)
      return io.stderr:write(tostring(self.start_msg) .. " with " .. tostring(mode) .. " [" .. tostring(misc) .. "]\n")
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, file_list)
      self.file_list = file_list
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
local InotifyWacher
do
  local _class_0
  local _parent_0 = Watcher
  local _base_0 = {
    get_dirs = function(self)
      local parse_dir
      parse_dir = require("moonscript.cmd.moonc").parse_dir
      local dirs
      do
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = self.file_list
        for _index_0 = 1, #_list_0 do
          local _des_0 = _list_0[_index_0]
          local file_path
          file_path = _des_0[1]
          local dir = parse_dir(file_path)
          if dir == "" then
            dir = "./"
          end
          local _value_0 = dir
          _accum_0[_len_0] = _value_0
          _len_0 = _len_0 + 1
        end
        dirs = _accum_0
      end
      return remove_dupes(dirs)
    end,
    each_update = function(self)
      return coroutine.wrap(function()
        local dirs = self:get_dirs()
        self:print_start("inotify", plural(#dirs, "dir"))
        local wd_table = { }
        local inotify = require("inotify")
        local handle = inotify.init()
        for _index_0 = 1, #dirs do
          local dir = dirs[_index_0]
          local wd = handle:addwatch(dir, inotify.IN_CLOSE_WRITE, inotify.IN_MOVED_TO)
          wd_table[wd] = dir
        end
        while true do
          local events = handle:read()
          if not (events) then
            break
          end
          for _index_0 = 1, #events do
            local _continue_0 = false
            repeat
              local ev = events[_index_0]
              local fname = ev.name
              if not (fname:match("%.moon$")) then
                _continue_0 = true
                break
              end
              local dir = wd_table[ev.wd]
              if dir ~= "./" then
                fname = dir .. fname
              end
              coroutine.yield(fname)
              _continue_0 = true
            until true
            if not _continue_0 then
              break
            end
          end
        end
      end)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "InotifyWacher",
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
  InotifyWacher = _class_0
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
      return coroutine.wrap(function()
        local lfs = require("lfs")
        local sleep = self:get_sleep_func()
        self:print_start("polling", plural(#self.file_list, "files"))
        local mod_time = { }
        while true do
          local _list_0 = self.file_list
          for _index_0 = 1, #_list_0 do
            local _continue_0 = false
            repeat
              local _des_0 = _list_0[_index_0]
              local file
              file = _des_0[1]
              local time = lfs.attributes(file, "modification")
              if not (time) then
                mod_time[file] = nil
                _continue_0 = true
                break
              end
              if not (mod_time[file]) then
                mod_time[file] = time
                _continue_0 = true
                break
              end
              if time > mod_time[file] then
                mod_time[file] = time
                coroutine.yield(file)
              end
              _continue_0 = true
            until true
            if not _continue_0 then
              break
            end
          end
          sleep(self.polling_rate)
        end
      end)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
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
  InotifyWacher = InotifyWacher
}
