
import unpack from require "moonscript.util"

describe "comprehension", ->
  it "should double every number", ->
    input = {1,2,3,4,5,6}
    output_1 = [i * 2 for _, i in pairs input ]
    output_2 = [i * 2 for i in *input ]

    assert.same output_1, {2,4,6,8,10,12}

  it "should create a slice", ->
    input = {1,2,3,4,5,6}

    slice_1 = [i for i in *input[1,3]]
    slice_2 = [i for i in *input[,3]]

    slice_3 = [i for i in *input[3,]]
    slice_4 = [i for i in *input[,]]

    slice_5 = [i for i in *input[,,2]]
    slice_6 = [i for i in *input[2,,2]]

    assert.same slice_1, {1,2,3}
    assert.same slice_1, slice_2
    assert.same slice_3, {3,4,5,6}
    assert.same slice_4, input

    assert.same slice_5, {1,3,5}
    assert.same slice_6, {2,4,6}

  it "should be able to assign to self", ->
    input = {1,2,3,4}
    output = input
    output = [i * 2 for i in *output]

    assert.same input, {1,2,3,4}
    assert.same output, {2,4,6,8}

    output = input
    output = [i * 2 for _,i in ipairs input]

    assert.same input, {1,2,3,4}
    assert.same output, {2,4,6,8}


describe "table comprehension", ->
  it "should copy table", ->
    input = { 1,2,3, hello: "world", thing: true }
    output = {k,v for k,v in pairs input }

    assert.is_true input != output
    assert.same input, output

  it "should support when", ->
    input = {
      color: "red"
      name: "fast"
      width: 123
    }

    output = { k,v for k,v in pairs input when k != "color" }

    assert.same output, { name: "fast", width: 123 }

  it "should do unpack", ->
    input = {4,9,16,25}
    output = {i, math.sqrt i for i in *input}

    assert.same output, { [4]: 2, [9]: 3, [16]: 4, [25]: 5 }

  it "should use multiple return values", ->
    input = { {"hello", "world"}, {"foo", "bar"} }
    output = { unpack tuple for tuple in *input }

    assert.same output, { foo: "bar", hello: "world" }

