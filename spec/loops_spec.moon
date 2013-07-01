
describe "loops", ->
  it "should continue", ->
    input = {1,2,3,4,5,6}
    output = for x in *input
      continue if x % 2 == 1
      x

    assert.same output, { 2,4,6 }
