
module("moonscript.compile", package.seeall)
require "util"

-- setmetatable(_M, {
-- 	__call = setfenv(function(self, ...)
-- 		compile(...)
-- 	end, _G)
-- })

local compilers = {
	fncall = function(self, node)
		local _, name, args = unpack(node)
		return name .. self:args(args)
	end,
	args = function(self, node)
		local values = {}
		for _, v in ipairs(node) do
			table.insert(values, self:value(v))
		end
		return "(" .. table.concat(values, ", ") .. ")"
	end,
	value = function(self, node)
		if type(node) == "table" then 
			local op = unpack(node)
			return self[op](self, node)
		end

		return node
	end
}

_M.tree = function(tree)
	local buff = {}
	for _, line in ipairs(tree) do
		local op = line[1]
		local fn = compilers[op]
		if not fn then error("Unknown op: "..op) end
		table.insert(buff, compilers[op](compilers, line))
	end

	return table.concat(buff, "\n")
end


