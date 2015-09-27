-- test moon library

import with_dev from require "spec.helpers"

describe "moon", ->
  local moon

  with_dev ->
    moon = require "moon"

  it "should determine correct type", ->
    class Test

    things = {
      Test, Test!, 1, true, nil, "hello"
    }

    types = [moon.type t for t in *things]
    assert.same types, { Test, Test, "number", "boolean", "nil", "string" }

  it "should get upvalue", ->
    fn = do
      hello = "world"
      -> hello

    assert.same moon.debug.upvalue(fn, "hello"), "world"

  it "should set upvalue", ->
    fn = do
      hello = "world"
      -> hello

    moon.debug.upvalue fn, "hello", "foobar"
    assert.same fn!, "foobar"

  it "should run with scope", ->
    scope = hello: ->
    spy.on scope, "hello"
    moon.run_with_scope (-> hello!), scope

    assert.spy(scope.hello).was.called!


  it "should have access to old environment", ->
    scope = {}
    res = moon.run_with_scope (-> math), scope

    assert.same res, math

  it "should created bound proxy", ->
    class Hello
      state: 10
      method: (val) => "the state: #{@state}, the val: #{val}"

    hello = Hello!
    bound = moon.bind_methods hello

    assert.same bound.method("xxx"), "the state: 10, the val: xxx"

  it "should create defaulted table", ->
    fib = moon.defaultbl {[0]: 0, [1]: 1}, (i) => self[i - 1] + self[i - 2]
    fib[7]

    assert.same fib, { [0]: 0, 1, 1, 2, 3, 5, 8, 13 }

  it "should extend", ->
    t1 = { hello: "world's", cool: "shortest" }
    t2 = { cool: "boots", cowboy: "hat" }

    out = moon.extend t1, t2

    assert.same { out.hello, out.cool, out.cowboy }, { "world's", "shortest", "hat"}

  it "should make a copy", ->
    x = { "hello", yeah: "man" }
    y = moon.copy x

    x[1] = "yikes"
    x.yeah = "woman"

    assert.same y, { "hello", yeah: "man" }


  it "should mixin", ->
    class TestModule
      new: (@var) =>
      show_var: => "var is: #{@var}"

    class Second
      new: =>
        moon.mixin self, TestModule, "hi"

    obj = Second!

    assert.same obj\show_var!, "var is: hi"

  it "should mixin object", ->
    class First
      val: 10
      get_val: => "the val: #{@val}"

    class Second
      val: 20
      new: =>
        moon.mixin_object @, First!, { "get_val" }

    obj = Second!
    assert.same obj\get_val!, "the val: 10"

  it "should mixin table", ->
    a = { hello: "world", cat: "dog" }
    b = { cat: "mouse", foo: "bar" }
    moon.mixin_table a, b

    assert.same a, { hello: "world", cat: "mouse", foo: "bar"}

  it "should fold", ->
    numbers = {4,3,5,6,7,2,3}
    sum = moon.fold numbers, (a,b) -> a + b

    assert.same sum, 30
