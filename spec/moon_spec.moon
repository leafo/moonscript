-- test moon library

import with_dev from require "spec.helpers"

describe "moon", ->
  local moon

  with_dev ->
    moon = require "moon"

  describe "type", ->
    it "returns the class for a class", ->
      class Test
      assert.equal Test, moon.type Test

    it "returns the class for an instance", ->
      class Test
      assert.equal Test, moon.type Test!

    it "returns 'table' for __base", ->
      class Test
      assert.equal "table", moon.type Test.__base

    it "returns 'table' for __base with inheritance", ->
      class Parent
      class Child extends Parent
      assert.equal "table", moon.type Child.__base
      assert.equal "table", moon.type Parent.__base

    it "returns primitive type for non-tables", ->
      assert.equal "number", moon.type 1
      assert.equal "boolean", moon.type true
      assert.equal "nil", moon.type nil
      assert.equal "string", moon.type "hello"
      assert.equal "function", moon.type ->

    it "returns 'table' for plain tables", ->
      assert.equal "table", moon.type {}
      assert.equal "table", moon.type {hello: "world"}

    it "works with inheritance", ->
      class Parent
      class Child extends Parent
      assert.equal Child, moon.type Child!
      assert.equal Parent, moon.type Parent!
      assert.equal "table", moon.type Child.__base
      assert.equal "table", moon.type Parent.__base

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

  describe "is_class", ->
    it "returns true for a class", ->
      class Hello
      assert.truthy moon.is_class Hello

    it "returns false for an instance", ->
      class Hello
      assert.falsy moon.is_class Hello!

    it "returns false for __base", ->
      class Hello
      assert.falsy moon.is_class Hello.__base

    it "returns false for __base with inheritance", ->
      class Parent
      class Child extends Parent
      assert.falsy moon.is_class Child.__base
      assert.falsy moon.is_class Parent.__base

    it "returns false for plain tables and non-tables", ->
      assert.falsy moon.is_class {}
      assert.falsy moon.is_class 123
      assert.falsy moon.is_class "hello"
      assert.falsy moon.is_class nil
      assert.falsy moon.is_class true

    it "works with inheritance", ->
      class Parent
      class Child extends Parent
      assert.truthy moon.is_class Parent
      assert.truthy moon.is_class Child
      assert.falsy moon.is_class Child!

  describe "is_instance and is_class with imposter tables", ->
    it "rejects table with only __base set", ->
      fake = { __base: {} }
      assert.falsy moon.is_class fake
      assert.falsy moon.is_instance fake

    it "rejects table with __base and non-callable metatable", ->
      fake = setmetatable { __base: {} }, { __index: {} }
      assert.falsy moon.is_class fake
      assert.falsy moon.is_instance fake

    it "rejects table with self-referencing __index but no metatable", ->
      fake = {}
      fake.__index = fake
      assert.falsy moon.is_class fake
      assert.falsy moon.is_instance fake

    it "rejects table with __class set directly", ->
      fake = { __class: {} }
      assert.falsy moon.is_class fake
      assert.falsy moon.is_instance fake

    it "rejects table whose metatable has __class but not self-referencing __index", ->
      mt = { __class: {} }
      fake = setmetatable {}, mt
      assert.falsy moon.is_class fake
      assert.falsy moon.is_instance fake

    it "rejects table with self-referencing __index used as its own metatable", ->
      -- looks like a __base used as a metatable for itself
      fake = {}
      fake.__index = fake
      setmetatable fake, fake
      assert.falsy moon.is_class fake
      assert.falsy moon.is_instance fake

  describe "is_instance", ->
    it "returns true for an instance", ->
      class Hello
      assert.truthy moon.is_instance Hello!

    it "returns false for a class", ->
      class Hello
      assert.falsy moon.is_instance Hello

    it "returns false for __base", ->
      class Hello
      assert.falsy moon.is_instance Hello.__base

    it "returns false for __base with inheritance", ->
      class Parent
      class Child extends Parent
      assert.falsy moon.is_instance Child.__base
      assert.falsy moon.is_instance Parent.__base

    it "returns false for plain tables and non-tables", ->
      assert.falsy moon.is_instance {}
      assert.falsy moon.is_instance 123
      assert.falsy moon.is_instance "hello"
      assert.falsy moon.is_instance nil
      assert.falsy moon.is_instance true

    it "works with inheritance", ->
      class Parent
      class Child extends Parent
      assert.truthy moon.is_instance Parent!
      assert.truthy moon.is_instance Child!
      assert.falsy moon.is_instance Parent
      assert.falsy moon.is_instance Child

  describe "is_instance_of", ->
    it "returns true for direct instance", ->
      class Hello
      assert.truthy moon.is_instance_of Hello!, Hello

    it "returns true for instance of parent class", ->
      class Parent
      class Child extends Parent
      assert.truthy moon.is_instance_of Child!, Parent
      assert.truthy moon.is_instance_of Child!, Child

    it "returns false for instance of unrelated class", ->
      class A
      class B
      assert.falsy moon.is_instance_of A!, B
      assert.falsy moon.is_instance_of B!, A

    it "returns false for parent instance checked against child class", ->
      class Parent
      class Child extends Parent
      assert.falsy moon.is_instance_of Parent!, Child

    it "errors when value is not an instance", ->
      class Hello
      assert.has_error (-> moon.is_instance_of Hello, Hello), "is_instance_of: expected instance, got table"
      assert.has_error (-> moon.is_instance_of Hello.__base, Hello), "is_instance_of: expected instance, got table"
      assert.has_error (-> moon.is_instance_of {}, Hello), "is_instance_of: expected instance, got table"
      assert.has_error (-> moon.is_instance_of nil, Hello), "is_instance_of: expected instance, got nil"
      assert.has_error (-> moon.is_instance_of 123, Hello), "is_instance_of: expected instance, got number"

    it "errors when __base is passed as the value", ->
      class Parent
      class Child extends Parent
      assert.has_error (-> moon.is_instance_of Parent.__base, Parent), "is_instance_of: expected instance, got table"
      assert.has_error (-> moon.is_instance_of Child.__base, Child), "is_instance_of: expected instance, got table"
      assert.has_error (-> moon.is_instance_of Child.__base, Parent), "is_instance_of: expected instance, got table"

    it "returns false when __base is passed as the class", ->
      class Parent
      class Child extends Parent
      assert.falsy moon.is_instance_of Parent!, Parent.__base
      assert.falsy moon.is_instance_of Child!, Child.__base
      assert.falsy moon.is_instance_of Child!, Parent.__base

    it "errors when __base is on both sides", ->
      class Parent
      class Child extends Parent
      assert.has_error (-> moon.is_instance_of Parent.__base, Parent.__base), "is_instance_of: expected instance, got table"
      assert.has_error (-> moon.is_instance_of Child.__base, Child.__base), "is_instance_of: expected instance, got table"
      assert.has_error (-> moon.is_instance_of Child.__base, Parent.__base), "is_instance_of: expected instance, got table"
      assert.has_error (-> moon.is_instance_of Parent.__base, Child.__base), "is_instance_of: expected instance, got table"

    it "works with deep inheritance chain", ->
      class A
      class B extends A
      class C extends B
      assert.truthy moon.is_instance_of C!, A
      assert.truthy moon.is_instance_of C!, B
      assert.truthy moon.is_instance_of C!, C
      assert.falsy moon.is_instance_of A!, B
      assert.falsy moon.is_instance_of A!, C

  it "should fold", ->
    numbers = {4,3,5,6,7,2,3}
    sum = moon.fold numbers, (a,b) -> a + b

    assert.same sum, 30
