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

  it "reports assigning to constant import", ->
    code = unindent [[
      import insert from table
      insert = 5
    ]]

    assert.same unindent([[
      string input

      line 2: assigning to constant `insert`
      ======================================
      > insert = 5
    ]]), lint.lint_code code

  it "reports update op on constant import", ->
    code = unindent [[
      import count from require "thing"
      count += 1
    ]]

    assert.same unindent([[
      string input

      line 2: assigning to constant `count`
      =====================================
      > count += 1
    ]]), lint.lint_code code

  it "allows shadowing a constant import", ->
    code = unindent [[
      import insert from table
      insert {}, 1
      f = (insert) -> insert
      g = ->
        local insert
        insert = 5
        insert
      f g!
    ]]

    assert.is_nil (lint.lint_code code)

  -- loop variables are fresh locals in every loop form, writing them never
  -- touches the enclosing binding
  it "allows loop variables shadowing a constant import", ->
    code = unindent [[
      import x from table
      f = -> x
      for x = 1, 2
        x = 3
        f!
      for x in ipairs {}
        x = 4
        f!
      for x in *{1, 2}
        x = 5
        f!
    ]]

    assert.is_nil (lint.lint_code code)

  -- importing a name bound in an enclosing scope writes that binding
  -- instead of creating a local
  it "flags import overwriting an enclosing binding", ->
    code = unindent [[
      insert = "hello"
      f = ->
        import insert from table
        insert
      f!
    ]]

    assert.same unindent([[
      string input

      line 3: import overwrites existing binding `insert`
      ===================================================
      >   import insert from table
    ]]), lint.lint_code code

  it "flags import overwriting a binding in the same scope", ->
    code = unindent [[
      insert = "hello"
      import insert from table
      insert {}, 1
    ]]

    assert.same unindent([[
      string input

      line 2: import overwrites existing binding `insert`
      ===================================================
      > import insert from table
    ]]), lint.lint_code code

  it "flags a final import overwriting an enclosing binding", ->
    code = unindent [[
      insert = "hello"
      f = ->
        print insert
        import insert from table
      f!
    ]]

    assert.same unindent([[
      string input

      line 4: import overwrites existing binding `insert`
      ===================================================
      >   import insert from table
    ]]), lint.lint_code code

  it "flags import inside nested function overwriting a declared local", ->
    code = unindent [[
      f = ->
        local check_app_version
        reload = ->
          import check_app_version from require "helpers.api"
          print "reloaded"
        reload!
        check_app_version!
      f!
    ]]

    assert.same unindent([[
      string input

      line 4: import overwrites existing binding `check_app_version`
      ==============================================================
      >     import check_app_version from require "helpers.api"
    ]]), lint.lint_code code

  -- a repeated import writes the existing constant binding
  it "flags a repeated import", ->
    code = unindent [[
      import insert from table
      insert {}, 1
      do
        import insert from require "custom"
        insert 2
    ]]

    assert.same unindent([[
      string input

      line 4: assigning to constant `insert`
      =======================================
      >   import insert from require "custom"
    ]]), lint.lint_code code

  it "limits reporting to the given stages", ->
    code = unindent [[
      import insert from table
      insert = 5
      do
        unused_var = 1
      missing_global 10
    ]]

    result = lint.lint_code code, nil, nil, stages: {"constant_assign"}
    assert.same unindent([[
      string input

      line 2: assigning to constant `insert`
      ======================================
      > insert = 5
    ]]), result

    result = lint.lint_code code, nil, nil, stages: {"global_access", "unused"}
    assert.truthy result\match "accessing global"
    assert.truthy result\match "assigned but unused"
    assert.is_nil result\match "assigning to constant"

    assert.is_nil (lint.lint_code code, nil, nil, stages: {"import_overwrite"})
    assert.is_nil (lint.lint_code code, nil, nil, stages: {})

  it "formats output with the compact format", ->
    code = unindent [[
      import insert from table
      insert = 5
      do
        unused_var = 1
      f = -> missing_global 10
      f!
    ]]

    assert.same unindent([[
      test.moon:2:1: assigning to constant `insert` [constant_assign]
      test.moon:4:3: assigned but unused `unused_var` [unused]
      test.moon:5:7: accessing global `missing_global` [global_access]
    ]]), lint.lint_code code, "test.moon", nil, format: "compact"

  it "combines compact format with stage filter", ->
    code = unindent [[
      import insert from table
      insert = 5
      missing_global 10
    ]]

    result = lint.lint_code code, "test.moon", nil, {
      format: "compact"
      stages: {"global_access"}
    }
    assert.same "test.moon:3:1: accessing global `missing_global` [global_access]", result

  it "compact format returns nothing for clean code", ->
    assert.is_nil (lint.lint_code "x = 5\nprint x", "test.moon", nil, format: "compact")
