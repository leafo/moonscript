
-- remove front indentation from a multiline string, making it suitable to be
-- parsed
unindent = (str) ->
  indent = str\match "^%s+"
  return str unless indent
  (str\gsub("\n#{indent}", "\n")\gsub("%s+$", "")\gsub "^%s+", "")

in_dev = false

-- this will ensure any moonscript modules included come from the local
-- directory
with_dev = (fn) ->
  error "already in dev mode" if in_dev

  -- a package loader that only looks in currect directory
  import make_loader from require "loadkit"
  loader = make_loader "lua", nil, "./?.lua"

  import setup, teardown from require "busted"

  old_require = _G.require
  dev_cache = {}

  setup ->
    _G.require = (mod) ->
      return dev_cache[mod] if dev_cache[mod]

      testable = mod\match("moonscript%.") or mod == "moonscript" or
        mod\match("moon%.") or mod == "moon"

      if testable
        fname = assert loader(mod), "failed to find module: #{mod}"
        dev_cache[mod] = assert(loadfile fname)!
        return dev_cache[mod]

      old_require mod

    if fn
      fn!

  teardown ->
    _G.require = old_require
    in_dev = false

  dev_cache

{ :unindent, :with_dev }
