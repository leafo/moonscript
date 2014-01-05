
import insert from table
import Set from require "moonscript.data"
import Block from require "moonscript.compile"

-- globals allowed to be referenced
default_whitelist = Set {
  '_G'
  '_VERSION'
  'assert'
  'bit32'
  'collectgarbage'
  'coroutine'
  'debug'
  'dofile'
  'error'
  'getfenv'
  'getmetatable'
  'io'
  'ipairs'
  'load'
  'loadfile'
  'loadstring'
  'math'
  'module'
  'next'
  'os'
  'package'
  'pairs'
  'pcall'
  'print'
  'rawequal'
  'rawget'
  'rawlen'
  'rawset'
  'require'
  'select'
  'setfenv'
  'setmetatable'
  'string'
  'table'
  'tonumber'
  'tostring'
  'type'
  'unpack'
  'xpcall'

  "nil"
  "true"
  "false"
}

class LinterBlock extends Block
  new: (whitelist_globals=default_whitelist, ...) =>
    super ...
    @lint_errors = {}

    vc = @value_compilers
    @value_compilers = setmetatable {
      ref: (block, val) ->
        name = val[2]
        unless block\has_name(name) or whitelist_globals[name] or name\match "%."
          insert @lint_errors, {
            "accessing global #{name}"
            val[-1]
          }

        vc.ref block, val
    }, __index: vc

  block: (...) =>
    with super ...
      .block = @block
      .value_compilers = @value_compilers

format_lint = (errors, code, header) ->
  return unless next errors

  import pos_to_line, get_line from require "moonscript.util"
  formatted = for {msg, pos} in *errors
    if pos
      line = pos_to_line code, pos
      msg = "line #{line}: #{msg}"
      line_text = "> " .. get_line code, line

      sep_len = math.max #msg, #line_text
      table.concat {
        msg
        "="\rep sep_len
        line_text
      }, "\n"

    else
      msg

  table.insert formatted, 1, header if header
  table.concat formatted, "\n\n"


-- {
--   whitelist_globals: {
--     ["some_file_pattern"]: {
--       "some_var", "another_var"
--     }
--   }
-- }
whitelist_for_file = do
  local lint_config
  (fname) ->
    unless lint_config
      lint_config = {}
      pcall -> lint_config = require "lint_config"

    return default_whitelist unless lint_config.whitelist_globals
    final_list = {}
    for pattern, list in pairs lint_config.whitelist_globals
      if fname\match(pattern)
        for item in *list
          insert final_list, item

    setmetatable Set(final_list), __index: default_whitelist

lint_code = (code, name="string input", whitelist_globals) ->
  parse = require "moonscript.parse"
  tree, err = parse.string code
  return nil, err unless tree

  scope = LinterBlock whitelist_globals
  scope\stms tree
  format_lint scope.lint_errors, code, name

lint_file = (fname) ->
  f, err = io.open fname
  return nil, err unless f
  lint_code f\read("*a"), fname, whitelist_for_file fname


{ :lint_code, :lint_file }
