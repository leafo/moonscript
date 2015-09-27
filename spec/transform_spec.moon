
describe "moonscript.transform.statements", ->
  describe "last_stm", ->
    import last_stm, Run from require "moonscript.transform.statements"

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


