local unpack = unpack or table.unpack
local ntype
ntype = function(node)
  if type(node) == "table" then
    return node[1]
  end
  return "value"
end
local chain_assignable = {
  index = true,
  dot = true,
  slice = true
}
local is_assignable
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
local flatten_explist = flatten_or_mark("explist")
local format_assign
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
local format_single_assign
format_single_assign = function(lhs, assign)
  if assign then
    return format_assign({
      lhs
    }, assign)
  end
  return lhs
end
local join_chain
join_chain = function(callee, args)
  if #args == 0 then
    return callee
  end
  args = {
    "call",
    args
  }
  if ntype(callee) == "chain" then
    table.insert(callee, args)
    return callee
  end
  return {
    "chain",
    callee,
    args
  }
end
return {
  ntype = ntype,
  is_assignable = is_assignable,
  format_assign = format_assign,
  format_single_assign = format_single_assign,
  join_chain = join_chain
}
