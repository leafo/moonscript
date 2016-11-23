import Block from require "moonscript.compile"
import ref from require "spec.factory"

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
    }
      it "compiles #{name}", ->
        node = node!
        assert.same expected, compile_node(node)


