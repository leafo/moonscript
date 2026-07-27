-- Transform helpers for the grammar's Cfn callbacks. The callbacks
-- themselves live as code strings in grammar.moon and require this module
-- at parser load.
--
-- format_assign raises error({node, msg}) for invalid assignment targets;
-- it propagates out of parse() and is formatted by moonscript/parse.moon.

unpack = unpack or table.unpack

-- never called with nil: that would report "value"
ntype = (node) ->
  if type(node) == "table"
    return node[1]

  "value"

chain_assignable = {index: true, dot: true, slice: true}

is_assignable = (node) ->
  return false if node == "..."

  switch ntype node
    when "ref", "self", "value", "self_class", "table"
      true
    when "chain"
      chain_assignable[ntype node[#node]]
    else
      false

flatten_or_mark = (name) ->
  (tbl) ->
    return tbl[1] if #tbl == 1
    table.insert tbl, 1, name
    tbl

flatten_explist = flatten_or_mark "explist"

format_assign = (lhs_exps, assign) ->
  unless assign
    return flatten_explist lhs_exps

  for assign_exp in *lhs_exps
    unless is_assignable assign_exp
      error {assign_exp, "left hand expression is not assignable"}

  t = ntype assign
  switch t
    when "assign"
      {"assign", lhs_exps, unpack assign, 2}
    when "update"
      {"update", lhs_exps[1], unpack assign, 2}
    else
      error "unknown assign expression: #{t}"

format_single_assign = (lhs, assign) ->
  if assign
    return format_assign {lhs}, assign

  lhs

join_chain = (callee, args) ->
  return callee if #args == 0
  args = {"call", args}

  if ntype(callee) == "chain"
    table.insert callee, args
    return callee

  {"chain", callee, args}

{ :ntype, :is_assignable, :format_assign, :format_single_assign, :join_chain }
