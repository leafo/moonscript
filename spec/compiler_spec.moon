import Block from require "moonscript.compile"

import ref, str from require "spec.factory"

-- no transform step
class SimpleBlock extends Block
  new: (...) =>
    super ...
    @transform = {
      value: (...) -> ...
      statement: (...) -> ...
    }

value = require "moonscript.compile.value"

describe "moonscript.compile", ->
  compile_node = (node) ->
    block = SimpleBlock!
    block\add block\value node
    lines = block._lines\flatten!
    lines[#lines] = nil if lines[#lines] == "\n"
    table.concat lines

  -- compiling lua ast
  describe "value", ->
    for {name, node, expected} in *{
      {
        "ref"
        -> {"ref", "hello_world"}
        "hello_world"
      }

      {
        "explist"
        -> { "explist", ref("a"), ref("b"), ref("c")}
        "a, b, c"
      }

      {
        "parens"
        -> { "parens", ref! }
        "(val)"
      }

      {
        "string (single quote)"
        -> {"string", "'", "Hello\\'s world"}
        "'Hello\\'s world'"
      }

      {
        "string (double quote)"
        -> {"string", '"', "Hello's world"}
        [["Hello's world"]]

      }

      {
        "string (lua)"
        -> {"string", '[==[', "Hello's world"}
        "[==[Hello's world]==]"
      }

      {
        "chain (single)"
        -> {"chain", ref!}
        "val"
      }

      {
        "chain (dot)"
        -> {"chain", ref!, {"dot", "zone"} }
        "val.zone"
      }

      {
        "chain (index)"
        -> {"chain", ref!, {"index", ref("x") } }
        "val[x]"
      }


      {
        "chain (call)"
        -> {"chain", ref!, {"call", { ref("arg") }} }
        "val(arg)"
      }

      {
        "chain"
        -> {
            "chain"
             ref!
            {"dot", "one"}
            {"index", str!}
            {"colon", "two"}
            {"call", { ref("arg") }}
          }
        'val.one["dogzone"]:two(arg)'
      }

    }
      it "compiles #{name}", ->
        node = node!
        assert.same expected, compile_node(node)


