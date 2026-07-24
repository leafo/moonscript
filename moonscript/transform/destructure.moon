
import ntype, mtype, build, is_assignable from require "moonscript.types"
import NameProxy from require "moonscript.transform.names"
import insert from table
import unpack from require "moonscript.util"

import user_error from require "moonscript.errors"

join = (...) ->
  with out = {}
    i = 1
    for tbl in *{...}
      for v in *tbl
        out[i] = v
        i += 1

has_destructure = (names) ->
  for n in *names
    return true if ntype(n) == "table"
  false

-- can this value provide more than one return value
is_multi_return = (node) ->
  return true if node == "..."
  return false unless type(node) == "table"
  switch node[1]
    when "chain"
      ntype(node[#node]) == "call"
    when "explist"
      true
    else
      false

extract_assign_names = (name, accum={}, prefix={}) ->

  i = 1
  for tuple in *name[2]
    value, suffix = if #tuple == 1
      s = {"index", {"number", i}}
      i += 1
      tuple[1], s
    else
      key = tuple[1]

      s = if ntype(key) == "key_literal"
        key_name = key[2]
        if ntype(key_name) == "colon"
          key_name
        else
          {"dot", key_name}
      else
        {"index", key}

      tuple[2], s

    suffix = join prefix, {suffix}

    if ntype(value) == "table"
      extract_assign_names value, accum, suffix
    elseif is_assignable value
      insert accum, {value, suffix}
    else
      pos = type(value) == "table" and value[-1] or name[-1]
      if value == "..."
        user_error "Can't destructure into '...'", pos
      elseif ntype(value) == "chain"
        user_error "Can't destructure into chain ending in #{ntype value[#value]}", pos
      else
        user_error "Can't destructure value of type: #{ntype value}", pos

  accum

-- can the receiver be referenced directly as the base of a chain? anything
-- not recognized here is copied to a temporary name before destructuring.
-- exp, table and string are chainable because the compiler wraps them in
-- parentheses
keyword_refs = {nil: true, true: true, false: true}

chainable_receiver = (node) ->
  switch type node
    when "string"
      -- legacy transformers use plain strings for names
      node != "..." and not keyword_refs[node]
    when "table"
      switch node[1]
        when "ref"
          not keyword_refs[node[2]]
        when "chain", "self", "self_class", "temp_name", "parens", "exp", "table", "string"
          true
        else
          false
    else
      false

build_assign = (scope, destruct_literal, receiver) ->
  assert receiver,  "attempting to build destructure assign with no receiver"

  extracted_names = extract_assign_names destruct_literal

  names = {}
  values = {}

  inner = {"assign", names, values}

  obj = if chainable_receiver(receiver) and (scope\is_local(receiver) or #extracted_names == 1)
    receiver
  else
    with obj = NameProxy "obj"
      inner = build.do {
        build.assign_one obj, receiver
        {"assign", names, values}
      }

  for tuple in *extracted_names
    insert names, tuple[1]
    chain = if obj
      NameProxy.chain obj, unpack tuple[2]
    else
      "nil"
    insert values, chain

  build.group {
    {"declare", names}
    inner
  }

-- applies to destructuring to a assign node
split_assign = (scope, assign) ->
  names, values = unpack assign, 2

  g = {}
  total_names = #names
  total_values = #values

  -- if the final value can return multiple values then the names consuming
  -- its returns must be assigned in a single statement. destructuring
  -- literals among them receive a temporary that is unpacked afterwards
  local suffix_start
  if total_names > total_values and is_multi_return values[total_values]
    for i=total_values, total_names
      if ntype(names[i]) == "table"
        suffix_start = total_values
        break

  -- We have to break apart the assign into groups of regular
  -- assigns, and then the destructuring assignments
  start = 1
  stop = suffix_start and suffix_start - 1 or total_names
  for i=1, stop
    n = names[i]
    if ntype(n) == "table"
      if i > start
        insert g, {
          "assign"
          for j=start,i-1 do names[j]
          for j=start,i-1 do values[j]
        }

      insert g, build_assign scope, n, values[i]

      start = i + 1

  if suffix_start
    -- plain names left over between the last destructure and the suffix
    if start <= stop
      insert g, {
        "assign"
        for j=start,stop do names[j]
        for j=start,stop do values[j]
      }

    suffix_names = {}
    destructures = {}
    for i=suffix_start, total_names
      name = names[i]
      if ntype(name) == "table"
        proxy = NameProxy "destruct"
        insert suffix_names, proxy
        insert destructures, {name, proxy}
      else
        insert suffix_names, name

    insert g, {"assign", suffix_names, {values[total_values]}}

    for {literal, proxy} in *destructures
      insert g, build_assign scope, literal, proxy
  elseif total_names >= start or total_values >= start
    name_slice = if total_names < start
      {"_"}
    else
      for i=start,total_names do names[i]

    value_slice = if total_values < start
      {"nil"}
    else
      for i=start,total_values do values[i]

    insert g, {"assign", name_slice, value_slice}

  build.group g

{ :has_destructure, :split_assign, :build_assign, :extract_assign_names }
