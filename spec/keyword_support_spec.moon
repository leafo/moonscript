
import with_dev from require "spec.helpers"

describe "keyword support", ->

  local moonscript

  with_dev ->
    moonscript = require "moonscript.base"

  it "should accept keywords with @", ->
    moon_src="class Test\n\tnew: => @if=true\n\tdo: => 1\n\ttest: => @if and @do!\ntest=Test!\ntest\\test!"
    lua_src=moonscript.to_lua moon_src
    assert.is_not_nil lua_src
    fn=(loadstring or load) lua_src
    assert.is_not_nil fn
    assert.same fn!, 1

  it "should accept keywords with @@", ->
    moon_src="class Test\n\tnew: => @@if=true\n\t@do: => 1\n\ttest: => @@if and @@do!\ntest=Test!\ntest\\test!"
    lua_src=moonscript.to_lua moon_src
    assert.is_not_nil lua_src
    fn=(loadstring or load) lua_src
    assert.is_not_nil fn
    assert.same fn!, 1
