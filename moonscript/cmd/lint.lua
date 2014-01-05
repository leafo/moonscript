local insert
do
  local _obj_0 = table
  insert = _obj_0.insert
end
local Set
do
  local _obj_0 = require("moonscript.data")
  Set = _obj_0.Set
end
local Block
do
  local _obj_0 = require("moonscript.compile")
  Block = _obj_0.Block
end
local default_whitelist = Set({
  '_G',
  '_VERSION',
  'assert',
  'bit32',
  'collectgarbage',
  'coroutine',
  'debug',
  'dofile',
  'error',
  'getfenv',
  'getmetatable',
  'io',
  'ipairs',
  'load',
  'loadfile',
  'loadstring',
  'math',
  'module',
  'next',
  'os',
  'package',
  'pairs',
  'pcall',
  'print',
  'rawequal',
  'rawget',
  'rawlen',
  'rawset',
  'require',
  'select',
  'setfenv',
  'setmetatable',
  'string',
  'table',
  'tonumber',
  'tostring',
  'type',
  'unpack',
  'xpcall',
  "nil",
  "true",
  "false"
})
local LinterBlock
do
  local _parent_0 = Block
  local _base_0 = {
    block = function(self, ...)
      do
        local _with_0 = _parent_0.block(self, ...)
        _with_0.block = self.block
        _with_0.value_compilers = self.value_compilers
        return _with_0
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, whitelist_globals, ...)
      if whitelist_globals == nil then
        whitelist_globals = default_whitelist
      end
      _parent_0.__init(self, ...)
      self.lint_errors = { }
      local vc = self.value_compilers
      self.value_compilers = setmetatable({
        ref = function(block, val)
          local name = val[2]
          if not (block:has_name(name) or whitelist_globals[name] or name:match("%.")) then
            insert(self.lint_errors, {
              "accessing global " .. tostring(name),
              val[-1]
            })
          end
          return vc.ref(block, val)
        end
      }, {
        __index = vc
      })
    end,
    __base = _base_0,
    __name = "LinterBlock",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
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
  LinterBlock = _class_0
end
local format_lint
format_lint = function(errors, code, header)
  if not (next(errors)) then
    return 
  end
  local pos_to_line, get_line
  do
    local _obj_0 = require("moonscript.util")
    pos_to_line, get_line = _obj_0.pos_to_line, _obj_0.get_line
  end
  local formatted
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #errors do
      local _des_0 = errors[_index_0]
      local msg, pos
      msg, pos = _des_0[1], _des_0[2]
      if pos then
        local line = pos_to_line(code, pos)
        msg = "line " .. tostring(line) .. ": " .. tostring(msg)
        local line_text = "> " .. get_line(code, line)
        local sep_len = math.max(#msg, #line_text)
        _accum_0[_len_0] = table.concat({
          msg,
          ("="):rep(sep_len),
          line_text
        }, "\n")
      else
        _accum_0[_len_0] = msg
      end
      _len_0 = _len_0 + 1
    end
    formatted = _accum_0
  end
  if header then
    table.insert(formatted, 1, header)
  end
  return table.concat(formatted, "\n\n")
end
local whitelist_for_file
do
  local lint_config
  whitelist_for_file = function(fname)
    if not (lint_config) then
      lint_config = { }
      pcall(function()
        lint_config = require("lint_config")
      end)
    end
    if not (lint_config.whitelist_globals) then
      return default_whitelist
    end
    local final_list = { }
    for pattern, list in pairs(lint_config.whitelist_globals) do
      if fname:match(pattern) then
        for _index_0 = 1, #list do
          local item = list[_index_0]
          insert(final_list, item)
        end
      end
    end
    return setmetatable(Set(final_list), {
      __index = default_whitelist
    })
  end
end
local lint_code
lint_code = function(code, name, whitelist_globals)
  if name == nil then
    name = "string input"
  end
  local parse = require("moonscript.parse")
  local tree, err = parse.string(code)
  if not (tree) then
    return nil, err
  end
  local scope = LinterBlock(whitelist_globals)
  scope:stms(tree)
  return format_lint(scope.lint_errors, code, name)
end
local lint_file
lint_file = function(fname)
  local f, err = io.open(fname)
  if not (f) then
    return nil, err
  end
  return lint_code(f:read("*a"), fname, whitelist_for_file(fname))
end
return {
  lint_code = lint_code,
  lint_file = lint_file
}
