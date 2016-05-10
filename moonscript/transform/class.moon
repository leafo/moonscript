import NameProxy, LocalName from require "moonscript.transform.names"
import Run from require "moonscript.transform.statements"

CONSTRUCTOR_NAME = "new"

import insert from table
import build, ntype, NOOP from require "moonscript.types"
import unpack from require "moonscript.util"

transform_super = (cls_name, on_base=true, block, chain) ->
  relative_parent = {
    "chain",
    cls_name
    {"dot", "__parent"}
  }

  return relative_parent unless chain

  chain_tail = { unpack chain, 3 }
  head = chain_tail[1]

  if head == nil
    return relative_parent

  new_chain = relative_parent

  switch head[1]
    -- calling super, inject calling name and self into chain
    when "call"
      if on_base
        insert new_chain, {"dot", "__base"}

      calling_name = block\get "current_method"
      assert calling_name, "missing calling name"
      chain_tail[1] = {"call", {"self", unpack head[2]}}

      if ntype(calling_name) == "key_literal"
        insert new_chain, {"dot", calling_name[2]}
      else
        insert new_chain, {"index", calling_name}

    -- colon call on super, replace class with self as first arg
    when "colon"
      call = chain_tail[2]
      -- calling chain tail
      if call and call[1] == "call"
        chain_tail[1] = {
          "dot"
          head[2]
        }

        chain_tail[2] = {
          "call"
          {
            "self"
            unpack call[2]
          }
        }

  insert new_chain, item for item in *chain_tail
  new_chain


super_scope = (value, t, key) ->
  local prev_method

  {
    "scoped",
    Run =>
      prev_method = @get "current_method"
      @set "current_method", key
      @set "super", t
    value
    Run =>
      @set "current_method", prev_method
  }

(node, ret, parent_assign) =>
  name, parent_val, body = unpack node, 2
  parent_val = nil if parent_val == ""

  parent_cls_name = NameProxy "parent"
  base_name = NameProxy "base"
  self_name = NameProxy "self"
  cls_name = NameProxy "class"

  -- super call on instance
  cls_instance_super = (...) -> transform_super cls_name, true, ...

  -- super call on parent class
  cls_super = (...) -> transform_super cls_name, false, ...

  -- split apart properties and statements
  statements = {}
  properties = {}
  for item in *body
    switch item[1]
      when "stm"
        insert statements, item[2]
      when "props"
        for tuple in *item[2,]
          if ntype(tuple[1]) == "self"
            {k,v} = tuple
            v = super_scope v, cls_super, {"key_literal", k[2]}
            insert statements, build.assign_one k, v
          else
            insert properties, tuple

  -- find constructor
  local constructor
  properties = for tuple in *properties
    key = tuple[1]
    if key[1] == "key_literal" and key[2] == CONSTRUCTOR_NAME
      constructor = tuple[2]
      continue
    else
      {key, val} = tuple
      {key, super_scope val, cls_instance_super, key}


  unless constructor
    constructor = if parent_val
      build.fndef {
        args: {{"..."}}
        arrow: "fat"
        body: {
          build.chain { base: "super", {"call", {"..."}} }
        }
      }
    else
      build.fndef!

  real_name = name or parent_assign and parent_assign[2][1]
  real_name = switch ntype real_name
    when "chain"
      last = real_name[#real_name]
      switch ntype last
        when "dot"
          {"string", '"', last[2]}
        when "index"
          last[2]
        else
          "nil"
    when "nil"
      "nil"
    else
      name_t = type real_name
      -- TODO: don't use string literal as ref
      flattened_name = if name_t == "string"
        real_name
      elseif name_t == "table" and real_name[1] == "ref"
        real_name[2]
      else
        error "don't know how to extract name from #{name_t}"

      {"string", '"', flattened_name}

  cls = build.table {
    {"__init", super_scope constructor, cls_super, {"key_literal", "__init"}}
    {"__base", base_name}
    {"__name", real_name} -- "quote the string"
    parent_val and {"__parent", parent_cls_name} or nil
  }

  -- looking up a name in the class object
  class_index = if parent_val
    class_lookup = build["if"] {
      cond: { "exp", {"ref", "val"}, "==", "nil" }
      then: {
        build.assign_one LocalName"parent", build.chain {
          base: "rawget"
          {
            "call", {
              {"ref", "cls"}
              {"string", '"', "__parent"}
            }
          }
        }

        build.if {
          cond: LocalName "parent"
          then: {
            build.chain {
              base: LocalName "parent"
              {"index", "name"}
            }
          }
        }
      }
    }
    insert class_lookup, {"else", {"val"}}

    build.fndef {
      args: {{"cls"}, {"name"}}
      body: {
        build.assign_one LocalName"val", build.chain {
          base: "rawget", {"call", {base_name, {"ref", "name"}}}
        }
        class_lookup
      }
    }
  else
    base_name

  cls_mt = build.table {
    {"__index", class_index}
    {"__call", build.fndef {
      args: {{"cls"}, {"..."}}
      body: {
        build.assign_one self_name, build.chain {
          base: "setmetatable"
          {"call", {"{}", base_name}}
        }
        build.chain {
          base: "cls.__init"
          {"call", {self_name, "..."}}
        }
        self_name
      }
    }}
  }

  cls = build.chain {
    base: "setmetatable"
    {"call", {cls, cls_mt}}
  }

  value = nil
  with build
    out_body = {
      Run =>
        -- make sure we don't assign the class to a local inside the do
        @put_name name if name

      {"declare", { cls_name }}
      {"declare_glob", "*"}

      parent_val and .assign_one(parent_cls_name, parent_val) or NOOP

      .assign_one base_name, {"table", properties}
      .assign_one base_name\chain"__index", base_name

      parent_val and .chain({
        base: "setmetatable"
        {"call", {
          base_name,
          .chain { base: parent_cls_name,  {"dot", "__base"}}
        }}
      }) or NOOP

      .assign_one cls_name, cls
      .assign_one base_name\chain"__class", cls_name

      .group if #statements > 0 then {
        .assign_one LocalName"self", cls_name
        .group statements
      }

      -- run the inherited callback
      parent_val and .if({
        cond: {"exp", parent_cls_name\chain "__inherited" }
        then: {
          parent_cls_name\chain "__inherited", {"call", {
            parent_cls_name, cls_name
          }}
        }
      }) or NOOP

      .group if name then {
        .assign_one name, cls_name
      }

      if ret
        ret cls_name
    }

    value = .group {
      .group if ntype(name) == "value" then {
        .declare names: {name}
      }

      .do out_body
    }

  value
