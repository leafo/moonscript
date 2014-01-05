
describe "class", ->
  it "should make a class with constructor", ->
    class Thing
      new: =>
        @color = "blue"

    instance = Thing!

    assert.same instance, { color: "blue" }

  it "should have instance methods", ->
    class Thing
      get_color: => @color

      new: =>
        @color = "blue"

    instance = Thing!
    assert.same instance\get_color!, "blue"


  it "should have class property", ->
    class Thing
      color: "blue"
      get_color: => @color

    instance = Thing!
    assert.same instance\get_color!, "blue"
    assert.same Thing.color, "blue"

  it "should inherit another class", ->
    class Base
      get_property: => @[@property]

      new: (@property) =>

    class Thing extends Base
      color: "green"

    instance = Thing "color"
    assert.same instance\get_property!, "green"

  it "should call super constructor", ->
    class Base
      new: (@property) =>

    class Thing extends Base
      new: (@name) =>
        super "name"

    instance = Thing "the_thing"

    assert.same instance.property, "name"
    assert.same instance.name, "the_thing"


  it "should call super method", ->
    class Base
      _count: 111
      counter: => @_count

    class Thing extends Base
      counter: => "%08d"\format super!

    instance = Thing!
    assert.same instance\counter!, "00000111"

  it "should get super class", ->
    class Base
    class Thing extends Base
      get_super: => super

    instance = Thing!
    assert.is_true instance\get_super! == Base

  it "should get a bound method from super", ->
    class Base
      count: 1
      get_count: => @count

    class Thing extends Base
      get_count: => "this is wrong"
      get_method: => super\get_count

    instance = Thing!
    assert.same instance\get_method!!, 1

  it "should have class properties", ->
    class Base
    class Thing extends Base

    instance = Thing!

    assert.same Base.__name, "Base"
    assert.same Thing.__name, "Thing"
    assert.is_true Thing.__parent == Base

    assert.is_true instance.__class == Thing

  it "should have name when assigned", ->
    Thing = class
    assert.same Thing.__name, "Thing"


  it "should not expose class properties on instance", ->
    class Thing
      @height: 10

    Thing.color = "blue"

    instance = Thing!
    assert.same instance.color, nil
    assert.same instance.height, nil

  it "should expose new things added to __base", ->
    class Thing

    instance = Thing!
    Thing.__base.color = "green"

    assert.same instance.color, "green"

  it "should call with correct receiver", ->
    local instance

    class Thing
      is_class: => assert.is_true @ == Thing
      is_instance: => assert.is_true @ == instance

      go: =>
        @@is_class!
        @is_instance!

    instance = Thing!
    instance\go!

