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

