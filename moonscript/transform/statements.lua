local ntype, mtype
do
  local _obj_0 = require("moonscript.types")
  ntype, mtype = _obj_0.ntype, _obj_0.mtype
end
local Run
do
  local _class_0
  local _base_0 = {
    call = function(self, state)
      return self.fn(state)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, fn)
      self.fn = fn
      self[1] = "run"
    end,
    __base = _base_0,
    __name = "Run"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Run = _class_0
end
local last_stm
last_stm = function(stms)
  local last_exp_id = 0
  for i = #stms, 1, -1 do
    local stm = stms[i]
    if stm and mtype(stm) ~= Run then
      if ntype(stm) == "group" then
        return last_stm(stm[2])
      end
      last_exp_id = i
      break
    end
  end
  return stms[last_exp_id], last_exp_id, stms
end
local transform_last_stm
transform_last_stm = function(stms, fn)
  local _, last_idx, _stms = last_stm(stms)
  if _stms ~= stms then
    error("cannot transform last node in group")
  end
  return (function()
    local _accum_0 = { }
    local _len_0 = 1
    for i, stm in ipairs(stms) do
      if i == last_idx then
        _accum_0[_len_0] = {
          "transform",
          stm,
          fn
        }
      else
        _accum_0[_len_0] = stm
      end
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)()
end
local chain_is_stub
chain_is_stub = function(chain)
  local stub = chain[#chain]
  return stub and ntype(stub) == "colon"
end
return {
  Run = Run,
  last_stm = last_stm,
  transform_last_stm = transform_last_stm,
  chain_is_stub = chain_is_stub
}
