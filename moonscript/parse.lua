local errors = require("moonscript.parse.errors")
local parser = require("moonscript.parse.native")
return {
  string = function(str)
    local ok, result, label, err_pos = pcall(parser.parse, str)
    if not (ok) then
      if type(result) == "table" then
        local node, msg
        node, msg = result[1], result[2]
        local node_pos = type(node) == "table" and node[-1]
        if node_pos then
          return nil, errors.format(str, node_pos, msg)
        end
        return nil, "failed to parse: " .. tostring(msg)
      end
      return nil, tostring(result)
    end
    if not (result) then
      if err_pos then
        return nil, errors.format(str, err_pos, label or "failed to parse")
      end
      return nil, "failed to parse"
    end
    return result
  end
}
