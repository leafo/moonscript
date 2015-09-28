-- moonscript module

import with_dev from require "spec.helpers"

describe "moonscript.base", ->
  with_dev!

  it "should create moonpath", ->
    path = ";./?.lua;/usr/share/lua/5.1/?.lua;/usr/share/lua/5.1/?/init.lua;/usr/lib/lua/5.1/?.luac;/home/leafo/.luarocks/lua/5.1/?.lua"
    import create_moonpath from require "moonscript.base"
    assert.same "./?.moon;/usr/share/lua/5.1/?.moon;/usr/share/lua/5.1/?/init.moon;/home/leafo/.luarocks/lua/5.1/?.moon", create_moonpath(path)

