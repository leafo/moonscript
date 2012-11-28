
import ntype, build from require "moonscript.types"
import NameProxy from require "moonscript.transform.names"
import insert from table

import user_error from require "moonscript.compile"

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

build_assign = (extracted_names, receiver) ->
  obj = NameProxy "obj"
  names = {}
  values = {}

  for tuple in *extracted_names
    insert names, tuple[1]
    insert values, obj\chain unpack tuple[2]

  build.group {
    {"declare", names}
    build.do {
      build.assign_one obj, receiver
      {"assign", names, values}
    }
  }

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
        {"dot", key[2]}
      else
        {"index", key}

      tuple[2], s

    suffix = join prefix, {suffix}

    t = ntype value
    if t == "value" or t == "chain" or t == "self"
      insert accum, {value, suffix}
    elseif t == "table"
      extract_assign_names value, accum, suffix
    else
      user_error "Can't destructure value of type: #{ntype value}"

  accum

-- applies to destructuring to a assign node
split_assign = (assign) ->
  names, values = unpack assign, 2

  g = {}
  total_names = #names
  total_values = #values

  -- We have to break apart the assign into groups of regular
  -- assigns, and then the destructuring assignments
  start = 1
  for i, n in ipairs names
    if ntype(n) == "table"
      if i > start
        stop = i - 1
        insert g, {
          "assign"
          for i=start,stop
            names[i]
          for i=start,stop
            values[i]
        }

      extracted = extract_assign_names n
      insert g, build_assign extracted, values[i]

      start = i + 1

  if total_names >= start or total_values >= start
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

{ :has_destructure, :split_assign, :extract_assign_names, :build_assign }
