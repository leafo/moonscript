local append = table.insert
local builtin_whitelist_globals = {
  '_G',
  '_VERSION',
  'assert',
  'collectgarbage',
  'dofile',
  'error',
  'getfenv',
  'getmetatable',
  'ipairs',
  'load',
  'loadfile',
  'loadstring',
  'module',
  'next',
  'pairs',
  'pcall',
  'print',
  'rawequal',
  'rawget',
  'rawset',
  'require',
  'select',
  'setfenv',
  'setmetatable',
  'tonumber',
  'tostring',
  'type',
  'unpack',
  'xpcall',
  'coroutine',
  'debug',
  'io',
  'math',
  'os',
  'package',
  'string',
  'table',
  'true',
  'false',
  'nil'
}
local config_for
config_for = function(path)
  local has_moonscript = pcall(require, 'moonscript')
  local look_for = {
    'lint_config.lua'
  }
  if has_moonscript then
    table.insert(look_for, 1, 'lint_config.moon')
  end
  local exists
  exists = function(f)
    local fh = io.open(f, 'r')
    if fh then
      fh:close()
      return true
    end
    return false
  end
  local dir = path:match('(.+)[/\\].+$') or path
  while dir do
    for _index_0 = 1, #look_for do
      local name = look_for[_index_0]
      local config = tostring(dir) .. "/" .. tostring(name)
      if exists(config) then
        return config
      end
    end
    dir = dir:match('(.+)[/\\].+$')
  end
  if not (path:match('^/')) then
    for _index_0 = 1, #look_for do
      local name = look_for[_index_0]
      if exists(name) then
        return name
      end
    end
  end
  return nil
end
local load_config_from
load_config_from = function(config, file)
  if type(config) == 'string' then
    local loader = loadfile
    if config:match('.moon$') then
      loader = require("moonscript.base").loadfile
    end
    local chunk = assert(loader(config))
    config = chunk() or { }
  end
  local opts = {
    report_loop_variables = config.report_loop_variables,
    report_params = config.report_params
  }
  local _list_0 = {
    'whitelist_globals',
    'whitelist_loop_variables',
    'whitelist_params',
    'whitelist_unused',
    'whitelist_shadowing'
  }
  for _index_0 = 1, #_list_0 do
    local list = _list_0[_index_0]
    if config[list] then
      local wl = { }
      for k, v in pairs(config[list]) do
        if file:find(k) then
          for _index_1 = 1, #v do
            local token = v[_index_1]
            append(wl, token)
          end
        end
      end
      opts[list] = wl
    end
  end
  return opts
end
local whitelist
whitelist = function(...)
  local lists = {
    ...
  }
  if not (#lists > 0) then
    return function()
      return false
    end
  end
  local wl = { }
  local patterns = { }
  for _index_0 = 1, #lists do
    local list = lists[_index_0]
    for _index_1 = 1, #list do
      local p = list[_index_1]
      if p:match('^%w+$') then
        append(wl, p)
      else
        append(patterns, p)
      end
    end
  end
  do
    local _tbl_0 = { }
    for _index_0 = 1, #wl do
      local k = wl[_index_0]
      _tbl_0[k] = true
    end
    wl = _tbl_0
  end
  return function(sym)
    if wl[sym] then
      return true
    end
    for _index_0 = 1, #patterns do
      local p = patterns[_index_0]
      if sym:match(p) then
        return true
      end
    end
    return false
  end
end
local evaluator
evaluator = function(opts)
  if opts == nil then
    opts = { }
  end
  local report_params = opts.report_params
  if report_params == nil then
    report_params = false
  end
  local whitelist_params = whitelist(opts.whitelist_params or {
    '^_',
    '%.%.%.'
  })
  local report_loop_variables = opts.report_loop_variables
  if report_loop_variables == nil then
    report_loop_variables = true
  end
  local whitelist_loop_variables = whitelist(opts.whitelist_loop_variables or {
    '^_',
    'i',
    'j'
  })
  local report_shadowing = opts.report_shadowing
  if report_shadowing == nil then
    report_shadowing = true
  end
  local builtin_whitelist_shadowing = whitelist({
    '%.%.%.',
    '_ENV'
  })
  local whitelist_shadowing = whitelist(opts.whitelist_shadowing) or builtin_whitelist_shadowing
  local whitelist_global_access = whitelist(builtin_whitelist_globals, opts.whitelist_globals)
  local whitelist_unused = whitelist({
    '^_$',
    'tostring',
    '_ENV'
  }, opts.whitelist_unused)
  return {
    allow_global_access = function(p)
      return whitelist_global_access(p)
    end,
    allow_unused_param = function(p)
      return not report_params or whitelist_params(p)
    end,
    allow_unused_loop_variable = function(p)
      return not report_loop_variables or whitelist_loop_variables(p)
    end,
    allow_unused = function(p)
      return whitelist_unused(p)
    end,
    allow_shadowing = function(p)
      return not report_shadowing or (whitelist_shadowing(p) or builtin_whitelist_shadowing(p))
    end
  }
end
return {
  config_for = config_for,
  load_config_from = load_config_from,
  evaluator = evaluator
}
