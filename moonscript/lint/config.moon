append = table.insert

builtin_whitelist_globals = {
  '_G'
  '_VERSION'
  'assert'
  'collectgarbage'
  'dofile'
  'error'
  'getfenv'
  'getmetatable'
  'ipairs'
  'load'
  'loadfile'
  'loadstring'
  'module'
  'next'
  'pairs'
  'pcall'
  'print'
  'rawequal'
  'rawget'
  'rawset'
  'require'
  'select'
  'setfenv'
  'setmetatable'
  'tonumber'
  'tostring'
  'type'
  'unpack'
  'xpcall'
  'coroutine'
  'debug'
  'io'
  'math'
  'os'
  'package'
  'string'
  'table'

  'true',
  'false',
  'nil'
}

config_for = (path) ->
  has_moonscript = pcall require, 'moonscript'
  look_for = { 'lint_config.lua' }
  if has_moonscript
    table.insert look_for, 1, 'lint_config.moon'

  exists = (f) ->
    fh = io.open f, 'r'
    if fh
      fh\close!
      return true

    false

  dir = path\match('(.+)[/\\].+$') or path
  while dir
    for name in *look_for
      config = "#{dir}/#{name}"
      return config if exists(config)

    dir = dir\match('(.+)[/\\].+$')

  unless path\match('^/')
    for name in *look_for
      return name if exists(name)

  nil

load_config_from = (config, file) ->
  if type(config) == 'string' -- assume path to config
    loader = loadfile
    if config\match('.moon$')
      loader = require("moonscript.base").loadfile

    chunk = assert loader(config)
    config = chunk! or {}

  opts = {
    report_loop_variables: config.report_loop_variables,
    report_params: config.report_params
  }
  for list in *{
    'whitelist_globals',
    'whitelist_loop_variables',
    'whitelist_params',
    'whitelist_unused',
    'whitelist_shadowing'
  }
    if config[list]
      wl = {}
      for k, v in pairs config[list]
        if file\find(k)
          for token in *v
            append wl, token

      opts[list] = wl

  opts

whitelist = (...) ->
  lists = {...}
  unless #lists > 0
    return -> false

  wl = {}
  patterns = {}

  for list in *lists
    for p in *list
      if p\match '^%w+$'
        append wl, p
      else
        append patterns, p

  wl = {k, true for k in *wl}

  (sym) ->
    if wl[sym]
      return true

    for p in *patterns
      if sym\match(p)
        return true

    false

evaluator = (opts = {}) ->
  report_params = opts.report_params
  report_params = false if report_params == nil
  whitelist_params = whitelist opts.whitelist_params or {
    '^_',
    '%.%.%.'
  }

  report_loop_variables = opts.report_loop_variables
  report_loop_variables = true if report_loop_variables == nil
  whitelist_loop_variables = whitelist opts.whitelist_loop_variables or {
    '^_',
    'i',
    'j'
  }

  report_shadowing = opts.report_shadowing
  report_shadowing = true if report_shadowing == nil
  builtin_whitelist_shadowing = whitelist { '%.%.%.', '_ENV' }
  whitelist_shadowing = whitelist(opts.whitelist_shadowing) or builtin_whitelist_shadowing

  whitelist_global_access = whitelist builtin_whitelist_globals, opts.whitelist_globals
  whitelist_unused = whitelist {
    '^_$',
    'tostring',
    '_ENV'
  }, opts.whitelist_unused

  {
    allow_global_access: (p) ->
      whitelist_global_access(p)

    allow_unused_param: (p) ->
      not report_params or whitelist_params(p)

    allow_unused_loop_variable: (p) ->
      not report_loop_variables or whitelist_loop_variables(p)

    allow_unused: (p) ->
      whitelist_unused(p)

    allow_shadowing: (p) ->
      not report_shadowing or (
        whitelist_shadowing(p) or
        builtin_whitelist_shadowing(p)
      )
  }

:config_for, :load_config_from, :evaluator
