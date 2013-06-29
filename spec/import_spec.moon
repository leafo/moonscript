describe "import", ->
  it "should import from table", ->
    import sort, insert from table
    t = { 4,2,6 }
    insert t, 1
    sort t

    assert.same t, {1,2,4,6}

  it "should import from local", ->
    thing = { var: 10, hello: "world", func: => @var }
    import hello, \func from thing

    assert.same hello, thing.hello
    assert.same func!, thing.var

  it "should not call source multiple times", ->
    count = 0
    source = ->
      count += 1
      { hello: "world", foo: "bar" }

    import hello, foo from source!
    
    assert.same count, 1

