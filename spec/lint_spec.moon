import with_dev, unindent from require "spec.helpers"

describe "linter", ->
  local lint

  with_dev ->
    lint = require "moonscript.cmd.lint"

  it "reports unused assignments in nested blocks", ->
    code = unindent [[
      if true
        unused = 1
    ]]

    assert.same unindent([[
      string input

      line 2: assigned but unused `unused`
      ====================================
      >   unused = 1
    ]]), lint.lint_code code
