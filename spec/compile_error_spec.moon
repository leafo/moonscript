import with_dev, unindent from require "spec.helpers"

-- tests the user facing compile errors triggered by invalid code, including
-- the source position they point at
describe "compile errors", ->
  local to_error

  with_dev ->
    parse = require "moonscript.parse"
    compile = require "moonscript.compile"
    import pos_to_line from require "moonscript.util"

    to_error = (str) ->
      tree = assert parse.string str
      code, err, pos = compile.tree tree
      assert.is_nil code, "expected compile to fail"
      err, pos and pos_to_line str, pos

  for {name, code_str, expected_msg, expected_line} in *{
    {
      "short-colon stub outside of with"
      unindent [[
        print "hello"
        x = \foo
      ]]
      "Short-colon syntax must be called within a with block"
      2
    }

    {
      "short-dot outside of with"
      unindent [[
        print "hello"
        print "world"
        x = .field
      ]]
      "Short-dot syntax must be called within a with block"
      3
    }

    {
      "destructuring invalid value"
      unindent [[
        print "hello"
        {1} = thing
      ]]
      "Can't destructure value of type: number"
      2
    }

    {
      "continue outside of loop"
      unindent [[
        print "hello"
        continue
      ]]
      "continue must be inside of a loop"
      2
    }
  }
    it name, ->
      err, line = to_error code_str
      assert.same expected_msg, err
      assert.same expected_line, line
