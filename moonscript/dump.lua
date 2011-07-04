
module("moonscript.dump", package.seeall)

local function flat_value(op, depth)
	depth = depth or 1

	if type(op) == "string" then return '"'..op..'"' end
	if type(op) ~= "table" then return tostring(op) end
	local items = {}
	for _, item in ipairs(op) do
		table.insert(items, flat_value(item, depth+1))
	end

	local pos = op[-1]

	return "{"..(pos and "["..pos.."] " or "")..table.concat(items, ", ").."}"
end

function value(op)
	return flat_value(op)
end

function tree(block, depth)
	depth = depth or 0
	for _, op in ipairs(block) do
		print(flat_value(op))
	end
end

