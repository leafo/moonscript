
import build from require "moonscript.types"
import unpack from require "moonscript.util"

-- always declares as local
class LocalName
  new: (@name) => self[1] = "temp_name"
  get_name: => @name

-- creates a unique name when used
class NameProxy
  new: (@prefix) =>
    self[1] = "temp_name"

  get_name: (scope, dont_put=true) =>
    if not @name
      @name = scope\free_name @prefix, dont_put
    @name

  chain: (...) =>
    items = { base: @, ... }
    for k,v in ipairs items
      items[k] = if type(v) == "string"
        {"dot", v}
      else
        v

    build.chain items

  index: (key) =>
    if type(key) == "string"
      key = {"ref", key}

    build.chain {
      base: self, {"index", key}
    }

  __tostring: =>
    if @name
      ("name<%s>")\format @name
    else
      ("name<prefix(%s)>")\format @prefix

is_name_proxy = (v) ->
  return false unless type(v) == "table"

  switch v.__class
    when LocalName, NameProxy
      true

{ :NameProxy, :LocalName, :is_name_proxy }
