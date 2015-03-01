local unpack
unpack = require("moonscript.util").unpack
local P, C, S, Cp, Cmt, V
do
  local _obj_0 = require("lpeg")
  P, C, S, Cp, Cmt, V = _obj_0.P, _obj_0.C, _obj_0.S, _obj_0.Cp, _obj_0.Cmt, _obj_0.V
end
local ntype
ntype = require("moonscript.types").ntype
local Space
Space = require("moonscript.parse.literals").Space
local Indent = C(S("\t ") ^ 0) / function(str)
  do
    local sum = 0
    for v in str:gmatch("[\t ]") do
      local _exp_0 = v
      if " " == _exp_0 then
        sum = sum + 1
      elseif "\t" == _exp_0 then
        sum = sum + 4
      end
    end
    return sum
  end
end
local Cut = P(function()
  return false
end)
local ensure
ensure = function(patt, finally)
  return patt * finally + finally * Cut
end
local extract_line
extract_line = function(str, start_pos)
  str = str:sub(start_pos)
  do
    local m = str:match("^(.-)\n")
    if m then
      return m
    end
  end
  return str:match("^.-$")
end
local mark
mark = function(name)
  return function(...)
    return {
      name,
      ...
    }
  end
end
local pos
pos = function(patt)
  return (Cp() * patt) / function(pos, value)
    if type(value) == "table" then
      value[-1] = pos
    end
    return value
  end
end
local got
got = function(what)
  return Cmt("", function(str, pos)
    print("++ got " .. tostring(what), "[" .. tostring(extract_line(str, pos)) .. "]")
    return true
  end)
end
local flatten_or_mark
flatten_or_mark = function(name)
  return function(tbl)
    if #tbl == 1 then
      return tbl[1]
    end
    table.insert(tbl, 1, name)
    return tbl
  end
end
local is_assignable
do
  local chain_assignable = {
    index = true,
    dot = true,
    slice = true
  }
  is_assignable = function(node)
    if node == "..." then
      return false
    end
    local _exp_0 = ntype(node)
    if "ref" == _exp_0 or "self" == _exp_0 or "value" == _exp_0 or "self_class" == _exp_0 or "table" == _exp_0 then
      return true
    elseif "chain" == _exp_0 then
      return chain_assignable[ntype(node[#node])]
    else
      return false
    end
  end
end
local check_assignable
check_assignable = function(str, pos, value)
  if is_assignable(value) then
    return true, value
  else
    return false
  end
end
local format_assign
do
  local flatten_explist = flatten_or_mark("explist")
  format_assign = function(lhs_exps, assign)
    if not (assign) then
      return flatten_explist(lhs_exps)
    end
    for _index_0 = 1, #lhs_exps do
      local assign_exp = lhs_exps[_index_0]
      if not (is_assignable(assign_exp)) then
        error({
          assign_exp,
          "left hand expression is not assignable"
        })
      end
    end
    local t = ntype(assign)
    local _exp_0 = t
    if "assign" == _exp_0 then
      return {
        "assign",
        lhs_exps,
        unpack(assign, 2)
      }
    elseif "update" == _exp_0 then
      return {
        "update",
        lhs_exps[1],
        unpack(assign, 2)
      }
    else
      return error("unknown assign expression: " .. tostring(t))
    end
  end
end
local format_single_assign
format_single_assign = function(lhs, assign)
  if assign then
    return format_assign({
      lhs
    }, assign)
  else
    return lhs
  end
end
local sym
sym = function(chars)
  return Space * chars
end
local symx
symx = function(chars)
  return chars
end
local simple_string
simple_string = function(delim, allow_interpolation)
  local inner = P("\\" .. tostring(delim)) + "\\\\" + (1 - P(delim))
  if allow_interpolation then
    local interp = symx('#{') * V("Exp") * sym('}')
    inner = (C((inner - interp) ^ 1) + interp / mark("interpolate")) ^ 0
  else
    inner = C(inner ^ 0)
  end
  return C(symx(delim)) * inner * sym(delim) / mark("string")
end
local wrap_func_arg
wrap_func_arg = function(value)
  return {
    "call",
    {
      value
    }
  }
end
local flatten_func
flatten_func = function(callee, args)
  if #args == 0 then
    return callee
  end
  args = {
    "call",
    args
  }
  if ntype(callee) == "chain" then
    local stub = callee[#callee]
    if ntype(stub) == "colon_stub" then
      stub[1] = "colon"
      table.insert(stub, args)
    else
      table.insert(callee, args)
    end
    return callee
  end
  return {
    "chain",
    callee,
    args
  }
end
local flatten_string_chain
flatten_string_chain = function(str, chain, args)
  if not (chain) then
    return str
  end
  return flatten_func({
    "chain",
    str,
    unpack(chain)
  }, args)
end
local wrap_decorator
wrap_decorator = function(stm, dec)
  if not (dec) then
    return stm
  end
  return {
    "decorated",
    stm,
    dec
  }
end
local check_lua_string
check_lua_string = function(str, pos, right, left)
  return #left == #right
end
local self_assign
self_assign = function(name, pos)
  return {
    {
      "key_literal",
      name
    },
    {
      "ref",
      name,
      [-1] = pos
    }
  }
end
return {
  Indent = Indent,
  Cut = Cut,
  ensure = ensure,
  extract_line = extract_line,
  mark = mark,
  pos = pos,
  flatten_or_mark = flatten_or_mark,
  is_assignable = is_assignable,
  check_assignable = check_assignable,
  format_assign = format_assign,
  format_single_assign = format_single_assign,
  sym = sym,
  symx = symx,
  simple_string = simple_string,
  wrap_func_arg = wrap_func_arg,
  flatten_func = flatten_func,
  flatten_string_chain = flatten_string_chain,
  wrap_decorator = wrap_decorator,
  check_lua_string = check_lua_string,
  self_assign = self_assign
}
