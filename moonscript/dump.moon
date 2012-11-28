
flat_value = (op, depth=1) ->
  return '"'..op..'"' if type(op) == "string"
  return tostring(op) if type(op) != "table"

  items = [flat_value item, depth + 1 for item in *op]
  pos = op[-1]

  "{"..(pos and "["..pos.."] " or "")..table.concat(items, ", ").."}"

value = (op) ->
  flat_value op

tree = (block) ->
  print flat_value value for value in *block

{ :value, :tree }

