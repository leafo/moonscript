
import insert from table
import Set from require "moonscript.data"
import Block from require "moonscript.compile"

-- globals allowed to be referenced
whitelist_globals = Set {
  "print"
}

class LinterBlock extends Block
  new: (@lint_errors={}, ...) =>
    super ...

    vc = @value_compilers
    @value_compilers = setmetatable {
      raw_value: (block, name) ->

        if name\match("^[%w_]+$") and not block\has_name(name) and not whitelist_globals[name]
          stm = block.current_stms[block.current_stm_i]
          insert @lint_errors, {
            "accessing global #{name}"
            stm[-1]
          }

        vc.raw_value block, name
    }, __index: vc

  block: (...) =>
    with super ...
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
