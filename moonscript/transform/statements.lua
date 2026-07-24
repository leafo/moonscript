local types = require("moonscript.types")
local ntype, mtype, is_value, NOOP
ntype, mtype, is_value, NOOP = types.ntype, types.mtype, types.is_value, types.NOOP
local comprehension_has_value
comprehension_has_value = require("moonscript.transform.comprehension").comprehension_has_value
local insert
insert = table.insert
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
local continue_boundaries = {
  fndef = true,
  ["while"] = true,
  ["for"] = true,
  foreach = true,
  comprehension = true,
  tblcomprehension = true
}
local find_continues
find_continues = function(tbl, out)
  if out == nil then
    out = { }
  end
  for _index_0 = 1, #tbl do
    local item = tbl[_index_0]
    if type(item) == "table" then
      if item[1] == "continue" then
        insert(out, item)
      elseif not continue_boundaries[item[1]] then
        find_continues(item, out)
      end
    end
  end
  return out
end
local has_varargs
has_varargs = function(tbl)
  for _index_0 = 1, #tbl do
    local _continue_0 = false
    repeat
      local item = tbl[_index_0]
      local _exp_0 = type(item)
      if "string" == _exp_0 then
        if item == "..." then
          return true
        end
      elseif "table" == _exp_0 then
        local _exp_1 = item[1]
        if "fndef" == _exp_1 then
          _continue_0 = true
          break
        elseif "string" == _exp_1 then
          for i = 3, #item do
            local part = item[i]
            if type(part) == "table" and has_varargs(part) then
              return true
            end
          end
        else
          if has_varargs(item) then
            return true
          end
        end
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  return false
end
local implicitly_return
implicitly_return = function(scope)
  local is_top = true
  local fn
  fn = function(stm)
    local t = ntype(stm)
    if t == "decorated" then
      stm = scope.transform.statement(stm)
      t = ntype(stm)
    end
    if types.cascading[t] then
      is_top = false
      return scope.transform.statement(stm, fn)
    elseif types.manual_return[t] or not is_value(stm) then
      if is_top and t == "return" and stm[2] == "" then
        return NOOP
      else
        return stm
      end
    else
      if t == "comprehension" and not comprehension_has_value(stm) then
        return stm
      else
        return {
          "return",
          stm
        }
      end
    end
  end
  return fn
end
return {
  Run = Run,
  last_stm = last_stm,
  transform_last_stm = transform_last_stm,
  chain_is_stub = chain_is_stub,
  implicitly_return = implicitly_return,
  find_continues = find_continues,
  has_varargs = has_varargs
}
