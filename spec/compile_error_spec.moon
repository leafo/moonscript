import with_dev, unindent from require "spec.helpers"

-- tests the user facing compile errors triggered by invalid code, including
-- the source position they point at
describe "compile errors", ->
  local to_error, parse_fails

  with_dev ->
    parse = require "moonscript.parse"
    compile = require "moonscript.compile"
    import pos_to_line from require "moonscript.util"

    to_error = (str) ->
      tree = assert parse.string str
      code, err, pos = compile.tree tree
      assert.is_nil code, "expected compile to fail"
      err, pos and pos_to_line str, pos

    parse_fails = (str) ->
      tree, err = parse.string str
      assert.is_nil tree, "expected parse to fail: #{str}"
      assert.truthy err

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
      "destructuring into a function call"
      unindent [[
        print "hello"
        {foo!} = thing
      ]]
      "Can't destructure into chain ending in call"
      2
    }

    {
      "destructuring function argument into call"
      unindent [[
        print "hello"
        f = ({foo!}) -> foo
      ]]
      "Can't destructure into chain ending in call"
      2
    }

    {
      "destructuring function argument into invalid value"
      unindent [[
        print "hello"
        print "world"
        f = ({1}) -> nil
      ]]
      "Can't destructure value of type: number"
      3
    }

    {
      "destructured parameter followed by parameter of same name"
      unindent [[
        print "hello"
        f = ({:a}, a) -> a
      ]]
      "Can't destructure into 'a': name is bound by another parameter"
      2
    }

    {
      "destructured parameter preceded by parameter of same name"
      unindent [[
        print "hello"
        f = (a, {:a}) -> a
      ]]
      "Can't destructure into 'a': name is bound by another parameter"
      2
    }

    {
      "destructured parameter followed by self parameter of same name"
      unindent [[
        print "hello"
        f = ({:a}, @a) => a
      ]]
      "Can't destructure into 'a': name is bound by another parameter"
      2
    }

    {
      "destructured self parameter in fat arrow"
      unindent [[
        print "hello"
        f = ({:self}) => @x
      ]]
      "Can't destructure into 'self': name is bound by another parameter"
      2
    }

    {
      "two destructured parameters binding same name"
      unindent [[
        print "hello"
        f = ({:a}, {a: a}) -> a
      ]]
      "Can't destructure into 'a': name is bound by another parameter"
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

  -- a malformed interpolation must fail the parse instead of falling
  -- through to literal string content
  it "invalid string interpolation fails to parse", ->
    parse_fails [[x = "one #{three ..} two"]]
    parse_fails [[x = "abc#{"]]
    parse_fails [[x = "#{}"]]
