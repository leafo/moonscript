import ref, str from require "spec.factory"
import with_dev from require "spec.helpers"

describe "moonscript.compile", ->
  local compile_node

  with_dev ->
    import Block from require "moonscript.compile"

    -- no transform step
    class SimpleBlock extends Block
      new: (...) =>
        super ...
        @transform = {
          value: (...) -> ...
          statement: (...) -> ...
        }

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
        "number"
        -> {"number", "14"}
        "14"
      }

      {
        "minus"
        -> {"minus", ref!}
        "-val"
      }

      {
        "explist"
        -> { "explist", ref("a"), ref("b"), ref("c")}
        "a, b, c"
      }

      {
        "exp"
        -> {"exp", ref("a"), "+", ref("b"), "!=", ref("c")}
        "a + b ~= c"
      }

      {
        "exp (nested under tighter operator)"
        -> {"exp", {"exp", ref("a"), "..", ref("b")}, "*", ref("c")}
        "(a .. b) * c"
      }

      {
        "exp (nested under looser operator)"
        -> {"exp", ref("a"), "==", {"exp", ref("b"), "..", ref("c")}}
        "a == b .. c"
      }

      {
        "exp (nested right of equal precedence left associative)"
        -> {"exp", ref("a"), "-", {"exp", ref("b"), "+", ref("c")}}
        "a - (b + c)"
      }

      {
        "exp (nested concat left of concat keeps grouping)"
        -> {"exp", {"exp", ref("a"), "..", ref("b")}, "..", ref("c")}
        "(a .. b) .. c"
      }

      {
        "exp (nested concat right of concat stays flat)"
        -> {"exp", ref("a"), "..", {"exp", ref("b"), "..", ref("c")}}
        "a .. b .. c"
      }

      {
        "exp (nested left of right associative operator)"
        -> {"exp", {"exp", ref("x"), "^", ref("y")}, "^", ref("b")}
        "(x ^ y) ^ b"
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
        "self"
        -> {"self", ref!}
        "self.val"
      }

      {
        "self_class"
        -> {"self_class", ref!}
        "self.__class.val"
      }

      {
        "self_class_colon"
        -> {"self_class_colon", ref!}
        "self.__class:val"
      }

      {
        "not"
        -> {"not", ref!}
        "not val"
      }

      {
        "length"
        -> {"length", ref!}
        "#val"
      }

      {
        "length"
        -> {"length", ref!}
        "#val"
      }

      {
        "bitnot"
        -> {"bitnot", ref!}
        "~val"
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

      {
        "chain (self receiver)"
        -> {
          "chain"
          {"self", ref!}
          {"call", {ref "arg"} }
        }
        "self:val(arg)"
      }

      {
        "fndef (empty)"
        -> {"fndef", {}, {}, "slim", {}}
        "function() end"
      }

    }
      it "compiles #{name}", ->
        node = node!
        assert.same expected, compile_node(node)


