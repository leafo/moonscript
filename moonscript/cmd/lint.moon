
import insert from table
import Set from require "moonscript.data"
import Block from require "moonscript.compile"

-- globals allowed to be referenced
whitelist_globals = Set {
  'loadstring'
  'select'
  '_VERSION'
  'pcall'
  'package'
  'error'
  'rawget'
  'pairs'
  'xpcall'
  'rawlen'
  'io'
  'loadfile'
  'ipairs'
  'table'
  'require'
  'os'
  'module'
  'debug'
  'type'
  'getmetatable'
  'rawequal'
  'dofile'
  'unpack'
  'math'
  'load'
  'bit32'
  'string'
  'rawset'
  'tostring'
  'print'
  'assert'
  '_G'
  'next'
  'setmetatable'
  'tonumber'
  'collectgarbage'
  'coroutine'

  "nil"
  "true"
  "false"
}

class LinterBlock extends Block
  new: (@lint_errors={}, ...) =>
    super ...

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


lint_code = (code, name="string input") ->
  parse = require "moonscript.parse"
  tree, err = parse.string code
  return nil, err unless tree

  scope = LinterBlock!
  scope\stms tree
  format_lint scope.lint_errors, code, name

lint_file = (fname) ->
  f, err = io.open fname
  return nil, err unless f
  lint_code f\read("*a"), fname


{ :lint_code, :lint_file }
