-- MoonScript parser interface. The parser itself is generated from the
-- grammar in moonscript/parse/grammar.moon by pgen
-- (https://github.com/leafo/pgen), see `make generate`.
-- moonscript/parse/slow.lua is the same grammar generated as pure Lua, a
-- drop-in for distributions that can't build the C module.

errors = require "moonscript.parse.errors"
parser = require "moonscript.parse.native"

{
  -- parse a string as a file
  -- returns tree, or nil and error message
  string: (str) ->
    -- grammar transforms run during parse(); format_assign raises
    -- error({node, msg}) for invalid assignment targets
    ok, result, label, err_pos = pcall parser.parse, str

    unless ok
      if type(result) == "table"
        {node, msg} = result
        node_pos = type(node) == "table" and node[-1]

        if node_pos
          return nil, errors.format str, node_pos, msg

        return nil, "failed to parse: " .. tostring msg

      -- errors thrown by the parser itself (e.g. the recursion depth limit)
      -- are returned like any other parse failure, not raised
      return nil, tostring result

    unless result
      if err_pos
        return nil, errors.format str, err_pos, label or "failed to parse"

      return nil, "failed to parse"

    result
}
