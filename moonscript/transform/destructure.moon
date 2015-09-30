
import ntype, mtype, build from require "moonscript.types"
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

    switch ntype value
      when "value", "ref", "chain", "self"
        insert accum, {value, suffix}
      when "table"
        extract_assign_names value, accum, suffix
      else
        user_error "Can't destructure value of type: #{ntype value}"

  accum

build_assign = (scope, destruct_literal, receiver) ->
  extracted_names = extract_assign_names destruct_literal

  names = {}
  values = {}

  inner = {"assign", names, values}

  obj = if scope\is_local(receiver) or #extracted_names == 1
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

      insert g, build_assign scope, n, values[i]

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

{ :has_destructure, :split_assign, :build_assign, :extract_assign_names }
