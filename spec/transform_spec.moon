
import with_dev from require "spec.helpers"

describe "moonscript.transform.destructure", ->
  local extract_assign_names

  with_dev ->
    { :extract_assign_names } = require "moonscript.transform.destructure"

  it "extracts names from table destructure", ->
    des = {
      "table"
      {
        {{"key_literal", "hi"}, {"ref", "hi"}}
        {{"key_literal", "world"}, {"ref", "world"}}
      }
    }

    assert.same {
      {
        {"ref", "hi"} -- target
        {
          {"dot", "hi"}
        } -- chain suffix
      }

      {
        {"ref", "world"}
        {
          {"dot", "world"}
        }
      }

    }, extract_assign_names des

  it "extracts names from array destructure", ->
    des = {
      "table"
      {
        {{"ref", "hi"}}
      }
    }

    assert.same {
      {
        {"ref", "hi"}
        {
          {"index", {"number", 1}}
        }
      }
    }, extract_assign_names des

describe "moonscript.transform.statements", ->
  local last_stm, transform_last_stm, Run

  with_dev ->
    { :last_stm, :transform_last_stm, :Run } = require "moonscript.transform.statements"

  describe "last_stm", ->
    it "gets last statement from empty list", ->
      assert.same nil, (last_stm {})

    it "gets last statement", ->
      stms = {
        {"ref", "butt_world"}
        {"ref", "hello_world"}
      }

      stm, idx, t = last_stm stms
      assert stms[2] == stm
      assert.same 2, idx
      assert stms == t

    it "gets last statement ignoring run", ->
      stms = {
        {"ref", "butt_world"}
        {"ref", "hello_world"}
        Run => print "hi"
      }

      stm, idx, t = last_stm stms
      assert stms[2] == stm
      assert.same 2, idx
      assert stms == t

    it "gets last from within group", ->
      stms = {
        {"ref", "butt_world"}
        {"group", {
          {"ref", "hello_world"}
          {"ref", "cool_world"}
        }}
      }

      last = stms[2][2][2]

      stm, idx, t = last_stm stms
      assert stm == last, "should get last"
      assert.same 2, idx
      assert t == stms[2][2], "should get correct table"

  describe "transform_last_stm", ->

    it "transforms empty stms", ->
      before = {}
      after = transform_last_stm before, (n) -> {"wrapped", n}

      assert.same before, after
      assert before != after

    it "transforms stms", ->
      before = {
        {"ref", "butt_world"}
        {"ref", "hello_world"}
      }

      transformer = (n) -> n
      after = transform_last_stm before, transformer

      assert.same {
        {"ref", "butt_world"}
        {"transform", {"ref", "hello_world"}, transformer}
      }, after

    it "transforms empty stms ignoring runs", ->
      before = {
        {"ref", "butt_world"}
        {"ref", "hello_world"}
        Run => print "hi"
      }

      transformer = (n) -> n
      after = transform_last_stm before, transformer

      assert.same {
        {"ref", "butt_world"}
        {"transform", {"ref", "hello_world"}, transformer}
        before[3]
      }, after

