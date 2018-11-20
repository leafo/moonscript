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

  it "should destructure with colon ':' separated from table's element identifier", ->
    -- Create a table with the colon ':' separated
    -- from some of the element identifiers of the table
    futurists =
      sculptor: "Umberto Boccioni"
      painter : "Vladimir Burliuk"
      poet    : {
        name   : "F.T. Marinetti"
        address: { "Via Roma 42R", "Bellagio, Italy 22021"}
      }

    -- And destructure the 'futurists' table
    -- with some element identifiers separated from the colon ':'
    {
      sculptor: sculptorName,
      painter : painterName,
      poet    : {
        name   : poetName,
        address: { poetStreet, poetCity }
      }
    } = futurists

    assert.same sculptorName, "Umberto Boccioni"
    assert.same painterName, "Vladimir Burliuk"
    assert.same poetName, "F.T. Marinetti"
    assert.same poetStreet, "Via Roma 42R"
    assert.same poetCity, "Bellagio, Italy 22021"

