describe "destructure", ->
  it "should unpack array", ->
    input = {1,2,3}

    {a,b,c} = {1,2,3}
    {d,e,f} = input

    assert.same a, 1
    assert.same b, 2
    assert.same c, 3

    assert.same d, 1
    assert.same e, 2
    assert.same f, 3

  it "should destructure", ->
    futurists =
      sculptor: "Umberto Boccioni"
      painter: "Vladimir Burliuk"
      poet:
        name: "F.T. Marinetti"
        address: {
          "Via Roma 42R"
          "Bellagio, Italy 22021"
        }

    {poet: {:name, address: {street, city}}} = futurists

    assert.same name, "F.T. Marinetti"
    assert.same street, "Via Roma 42R"
    assert.same city, "Bellagio, Italy 22021"


-- argument destructuring is new syntax, so sources are compiled with the dev
-- compiler at runtime instead of being written directly in this file
describe "function argument destructure", ->
  import with_dev, unindent from require "spec.helpers"

  local run

  with_dev ->
    parse = require "moonscript.parse"
    compile = require "moonscript.compile"

    run = (str) ->
      tree = assert parse.string str
      code, err = compile.tree tree
      assert code, err
      chunk = assert (loadstring or load) code
      chunk!

  it "unpacks fields", ->
    result = run unindent [[
      f = ({:a, :b, :c}) -> a + b + c
      return f {a: 1, b: 2, c: 3}
    ]]
    assert.same 6, result

  it "unpacks multiple table arguments", ->
    result = run unindent [[
      dot = ({x: x1, y: y1}, {x: x2, y: y2}) -> x1 * x2 + y1 * y2
      return dot {x: 1, y: 2}, {x: 3, y: 4}
    ]]
    assert.same 11, result

  it "applies default value", ->
    result = run unindent [[
      f = ({:a, :b} = {a: 1, b: 2}) -> a + b
      return {f!, f {a: 10, b: 20}}
    ]]
    assert.same {3, 30}, result

  it "shadows outer variable instead of assigning it", ->
    result = run unindent [[
      x = "outer"
      f = ({:x}) -> x
      inner = f {x: "inner"}
      return {inner, x}
    ]]
    assert.same {"inner", "outer"}, result

  it "assigns self fields with fat arrow", ->
    result = run unindent [[
      obj = {total: 10}
      obj.add = ({:count}) => @total + count
      return obj\add {count: 5}
    ]]
    assert.same 15, result

  it "preserves surrounding args and varargs", ->
    result = run unindent [[
      f = (first, {:mid}, ...) -> {first, mid, select "#", ...}
      return f "a", {mid: "b"}, "x", "y"
    ]]
    assert.same {"a", "b", 2}, result

  it "later defaults see earlier destructured names", ->
    result = run unindent [[
      a = "outer"
      f = ({:a}, b = a) -> b
      return f {a: 42}
    ]]
    assert.same 42, result

  it "lowers self assigns after destructure in order", ->
    result = run unindent [[
      obj = {}
      obj.set = ({:base}, @x = base * 2) => @x
      first = obj\set {base: 3}
      return {first, obj.x, obj\set({base: 3}, 99)}
    ]]
    assert.same {6, 6, 99}, result

  it "chains destructure defaults left to right", ->
    result = run unindent [[
      f = ({:a} = {a: 1}, {:b} = {b: a + 10}) -> {a, b}
      return f!
    ]]
    assert.same {1, 11}, result
