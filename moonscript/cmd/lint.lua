local insert
insert = table.insert
local Set
Set = require("moonscript.data").Set
local Block
Block = require("moonscript.compile").Block
local mtype
mtype = require("moonscript.util").moon.type
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
local default_stages = {
  globals = true,
  unused = true
}
local LinterBlock
do
  local _class_0
  local _parent_0 = Block
  local _base_0 = {
    lint_mark_used = function(self, name)
      if self.lint_unused_names and self.lint_unused_names[name] then
        self.lint_unused_names[name] = false
        return 
      end
      if self.parent then
        return self.parent:lint_mark_used(name)
      end
    end,
    lint_check_unused = function(self)
      if not (self.stages.unused) then
        return 
      end
      if not (self.lint_unused_names and next(self.lint_unused_names)) then
        return 
      end
      local names_by_position = { }
      for name, pos in pairs(self.lint_unused_names) do
        local _continue_0 = false
        repeat
          if not (pos) then
            _continue_0 = true
            break
          end
          local _update_0 = pos
          names_by_position[_update_0] = names_by_position[_update_0] or { }
          insert(names_by_position[pos], name)
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      local tuples
      do
        local _accum_0 = { }
        local _len_0 = 1
        for pos, names in pairs(names_by_position) do
          _accum_0[_len_0] = {
            pos,
            names
          }
          _len_0 = _len_0 + 1
        end
        tuples = _accum_0
      end
      table.sort(tuples, function(a, b)
        return a[1] < b[1]
      end)
      for _index_0 = 1, #tuples do
        local _des_0 = tuples[_index_0]
        local pos, names
        pos, names = _des_0[1], _des_0[2]
        insert(self:get_root_block().lint_errors, {
          "assigned but unused " .. tostring(table.concat((function()
            local _accum_0 = { }
            local _len_0 = 1
            for _index_1 = 1, #names do
              local n = names[_index_1]
              _accum_0[_len_0] = "`" .. tostring(n) .. "`"
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)(), ", ")),
          pos
        })
      end
    end,
    render = function(self, ...)
      self:lint_check_unused()
      return _class_0.__parent.__base.render(self, ...)
    end,
    block = function(self, ...)
      do
        local _with_0 = _class_0.__parent.__base.block(self, ...)
        _with_0.block = self.block
        _with_0.render = self.render
        _with_0.get_root_block = self.get_root_block
        _with_0.stages = self.stages
        _with_0.lint_check_unused = self.lint_check_unused
        _with_0.lint_mark_used = self.lint_mark_used
        _with_0.value_compilers = self.value_compilers
        _with_0.statement_compilers = self.statement_compilers
        return _with_0
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, whitelist_globals, stages, ...)
      if whitelist_globals == nil then
        whitelist_globals = default_whitelist
      end
      if stages == nil then
        stages = default_stages
      end
      _class_0.__parent.__init(self, ...)
      self.get_root_block = function()
        return self
      end
      self.stages = stages
      self.lint_errors = { }
      local vc = self.value_compilers
      self.value_compilers = setmetatable({
        ref = function(block, val)
          local name = val[2]
          if self.stages.globals then
            if not (block:has_name(name) or whitelist_globals[name] or name:match("%.")) then
              insert(self.lint_errors, {
                "accessing global `" .. tostring(name) .. "`",
                val[-1]
              })
            end
          end
          if self.stages.unused then
            block:lint_mark_used(name)
          end
          return vc.ref(block, val)
        end
      }, {
        __index = vc
      })
      local sc = self.statement_compilers
      self.statement_compilers = setmetatable({
        assign = function(block, node)
          if self.stages.unused then
            local names = node[2]
            for _index_0 = 1, #names do
              local _continue_0 = false
              repeat
                local name = names[_index_0]
                if type(name) == "table" and name[1] == "temp_name" then
                  _continue_0 = true
                  break
                end
                local real_name, is_local = block:extract_assign_name(name)
                if not (is_local or real_name and not block:has_name(real_name, true)) then
                  _continue_0 = true
                  break
                end
                if real_name == "_" then
                  _continue_0 = true
                  break
                end
                block.lint_unused_names = block.lint_unused_names or { }
                block.lint_unused_names[real_name] = node[-1] or 0
                _continue_0 = true
              until true
              if not _continue_0 then
                break
              end
            end
          end
          return sc.assign(block, node)
        end
      }, {
        __index = sc
      })
    end,
    __base = _base_0,
    __name = "LinterBlock",
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
  local loaded_configs = { }
  whitelist_for_file = function(fname, config_module)
    if config_module == nil then
      config_module = "lint_config"
    end
    if not (loaded_configs[config_module]) then
      loaded_configs[config_module] = { }
      pcall(function()
        loaded_configs[config_module] = require(config_module)
      end)
    end
    local lint_config = loaded_configs[config_module]
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
local normalize_stages
normalize_stages = function(stages)
  if not (stages) then
    return default_stages
  end
  if stages.globals ~= nil or stages.unused ~= nil then
    return stages
  end
  local out = { }
  for _index_0 = 1, #stages do
    local stage = stages[_index_0]
    out[stage] = true
  end
  return out
end
local lint_code
lint_code = function(code, name, opts)
  if name == nil then
    name = "string input"
  end
  if opts == nil then
    opts = { }
  end
  local parse = require("moonscript.parse")
  local tree, err = parse.string(code)
  if not (tree) then
    return nil, err
  end
  local whitelist_globals = opts.whitelist_globals or default_whitelist
  local stages = normalize_stages(opts.stages)
  local scope = LinterBlock(whitelist_globals, stages)
  scope:stms(tree)
  scope:lint_check_unused()
  return format_lint(scope.lint_errors, code, name)
end
local lint_file
lint_file = function(fname, opts)
  if opts == nil then
    opts = { }
  end
  local f, err = io.open(fname)
  if not (f) then
    return nil, err
  end
  local config_module = opts.config_module or "lint_config"
  return lint_code(f:read("*a"), fname, {
    whitelist_globals = whitelist_for_file(fname, config_module),
    stages = opts.stages
  })
end
return {
  lint_code = lint_code,
  lint_file = lint_file
}
