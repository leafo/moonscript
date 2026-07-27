-- Unit tests for the parser. Expected trees are written out inline,
-- including [-1] position annotations. The lang_spec corpus covers whole
-- files from parse to compiled output; these are quick hand-checked cases.

import with_dev from require "spec.helpers"

describe "moonscript.parse", ->
  local parse

  with_dev ->
    parse = require "moonscript.parse"

  it "parses assignment", ->
    assert.same {
      {"assign"
        {{"ref", "x", [-1]: 1}}
        {{"number", "5", [-1]: 4}}
        [-1]: 1}
    }, parse.string "x = 5"

  it "parses an open call", ->
    assert.same {
      {"chain"
        {"ref", "print", [-1]: 1}
        {"call", {{"ref", "x", [-1]: 6}}}
        [-1]: 1}
    }, parse.string "print x"

  it "parses table with self-assign and string key", ->
    assert.same {
      {"assign"
        {{"ref", "t", [-1]: 1}}
        {{"table", {
          {{"key_literal", "name"}, {"ref", "name", [-1]: 11}}
          {{"string", '"', "k"}, {"ref", "v", [-1]: 17}}
        }, [-1]: 4}}
        [-1]: 1}
    }, parse.string [[t = {:name, "k": v}]]

  it "parses a function literal with binary op body", ->
    assert.same {
      {"assign"
        {{"ref", "f", [-1]: 1}}
        {{"fndef", {{"a"}}, {}, "slim", {
          {"exp", {"ref", "a", [-1]: 11}, "+", {"number", "1", [-1]: 15}, [-1]: 11}
        }, [-1]: 4}}
        [-1]: 1}
    }, parse.string "f = (a) -> a + 1"

  it "parses an indented block", ->
    assert.same {
      {"if", {"ref", "x", [-1]: 3}, {
        {"chain", {"ref", "y", [-1]: 8}, {"call", {}}, [-1]: 8}
      }, [-1]: 1}
    }, parse.string "if x\n  y!"

  it "parses lua strings, reconstructing the open delimiter", ->
    assert.same {
      {"assign"
        {{"ref", "x", [-1]: 1}}
        {{"string", "[==[", "str", [-1]: 4}}
        [-1]: 1}
    }, parse.string "x = [==[str]==]"

  it "parses an anonymous class with a nil name slot", ->
    tree = assert parse.string "x = class"
    class_node = tree[1][3][1]
    assert.same "class", class_node[1]
    assert.is_nil class_node[2]
    assert.same "", class_node[3]
    assert.same {}, class_node[4]

  it "parses an empty file", ->
    assert.same {}, parse.string ""

  it "parses a comment-only file", ->
    assert.same {}, parse.string "-- nothing here"

  it "fails on unbalanced parens", ->
    tree, err = parse.string "x = (a + b"
    assert.is_nil tree
    assert.is_string err

  it "fails on a bad outdent", ->
    tree = parse.string "if x\n    y\n  z"
    assert.is_nil tree

  it "rejects a non-assignable left hand side", ->
    tree, err = parse.string "f! = 5"
    assert.is_nil tree
    assert.matches "not assignable", err
    assert.matches "line 1", err

  it "reports a line position for parse failures", ->
    tree, err = parse.string "x = 1\ny = 2\nz = (a +"
    assert.is_nil tree
    assert.matches "line 3", err

    tree, err = parse.string 'x = "hello\ny = 1'
    assert.is_nil tree
    assert.matches "line 2", err

    tree, err = parse.string "import a from"
    assert.is_nil tree
    assert.matches "line 1", err

  -- regression: T() labels were tried in this grammar and removed. Value
  -- tries Comprehension before String, so at "[[" the parser attempts to
  -- parse string content as code; a label reached during such an attempt
  -- rejected valid programs like these.
  it "parses code-like content inside long strings", ->
    assert.is_table parse.string "y = [[if x then import a]] .. z"
    assert.is_table parse.string "x = [[=[hi]] .. 1"
    assert.is_table parse.string [=[x = y .. [[Flow:extend("]] .. z .. [[")]] .. w]=]

  it "keeps the parser reusable after a failed parse", ->
    tree = parse.string "x = ("
    assert.is_nil tree

    assert.same {
      {"assign"
        {{"ref", "x", [-1]: 1}}
        {{"number", "1", [-1]: 4}}
        [-1]: 1}
    }, parse.string "x = 1"

  it "returns nil, err instead of raising on the recursion depth limit", ->
    str = ("(")\rep 6000
    tree, err = parse.string str
    assert.is_nil tree
    assert.matches "max recursion depth", err

  it "disables do expressions inside loop headers", ->
    -- `do` after the while condition is the block keyword, not a do-expression
    tree = assert parse.string "while x do print 1"
    assert.same "while", tree[1][1]

    -- but a do-expression is fine in normal expression position
    tree = assert parse.string "x = do\n  5"
    assert.same "do", tree[1][3][1][1]

  it "handles interpolation containing a lua string", ->
    tree = assert parse.string [=[x = "a#{ [[long]] }b"]=]
    str = tree[1][3][1]
    assert.same "string", str[1]
    assert.same "a", str[3]
    assert.same "interpolate", str[4][1]
    assert.same "string", str[4][2][1]
    assert.same "[[", str[4][2][2]
    assert.same "long", str[4][2][3]
    assert.same "b", str[5]
