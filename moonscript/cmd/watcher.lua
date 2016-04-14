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
local Watcher
do
  local _class_0
  local _base_0 = { }
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
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "SleepWatcher"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  SleepWatcher = _class_0
end
return {
  Watcher = Watcher,
  SleepWatcher = SleepWatcher,
  InotifyWacher = InotifyWacher
}
