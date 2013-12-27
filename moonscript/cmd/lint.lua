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
local whitelist_globals = Set({
  'loadstring',
  'select',
  '_VERSION',
  'pcall',
  'package',
  'error',
  'rawget',
  'pairs',
  'xpcall',
  'rawlen',
  'io',
  'loadfile',
  'ipairs',
  'table',
  'require',
  'os',
  'module',
  'debug',
  'type',
  'getmetatable',
  'rawequal',
  'dofile',
  'unpack',
  'math',
  'load',
  'bit32',
  'string',
  'rawset',
  'tostring',
  'print',
  'assert',
  '_G',
  'next',
  'setmetatable',
  'tonumber',
  'collectgarbage',
  'coroutine',
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
        _with_0.value_compilers = self.value_compilers
        return _with_0
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, lint_errors, ...)
      if lint_errors == nil then
        lint_errors = { }
      end
      self.lint_errors = lint_errors
      _parent_0.__init(self, ...)
      local vc = self.value_compilers
      self.value_compilers = setmetatable({
        ref = function(block, val)
          local name = val[2]
          if not (block:has_name(name) or whitelist_globals[name]) then
            local stm = block.current_stms[block.current_stm_i]
            insert(self.lint_errors, {
              "accessing global " .. tostring(name),
              stm[-1]
            })
          end
          return vc.raw_value(block, val)
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
local lint_code
lint_code = function(code, name)
  if name == nil then
    name = "string input"
  end
  local parse = require("moonscript.parse")
  local tree, err = parse.string(code)
  if not (tree) then
    return nil, err
  end
  local scope = LinterBlock()
  scope:stms(tree)
  return format_lint(scope.lint_errors, code, name)
end
local lint_file
lint_file = function(fname)
  local f, err = io.open(fname)
  if not (f) then
    return nil, err
  end
  return lint_code(f:read("*a"), fname)
end
return {
  lint_code = lint_code,
  lint_file = lint_file
}
