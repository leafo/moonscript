
module("moonscript.compile", package.seeall)
require "util"

-- this doesn't work
-- setmetatable(_M, {
-- 	__call = setfenv(function(self, ...)
-- 		compile(...)
-- 	end, _G)
-- })


local map, bind = util.map, util.bind

local indent_char = "  "

local compilers = {
	_indent = 0,
	ichar = function(self)
		return indent_char:rep(self._indent)
	end,

	fncall = function(self, node)
		local _, name, args = unpack(node)
		return name .. self:args(args)
	end,
	fndef = function(self, node)
		local _, args, block = unpack(node)
		if #block == 1 then
			return ("function(%s) %s end"):format(
				table.concat(args, ", "), self:value(block[1]))
		end
		return ("function(%s)\n%s\n%send"):format(
			table.concat(args, ", "), self:block(block, 1), self:ichar())
	end,
	args = function(self, node)
		local values = {}
		for _, v in ipairs(node) do
			table.insert(values, self:value(v))
		end
		return "(" .. table.concat(values, ", ") .. ")"
	end,
	["if"] = function(self, node)
		local _, cond, block = unpack(node)
		return ("if %s then\n%s\n%send"):format(
			self:value(cond), self:block(block, 1), self:ichar())
	end,
	block = function(self, node, inc)
		if inc then self._indent = self._indent + inc end
		local lines = {}
		local i = self:ichar()
		for _, ln in ipairs(node) do
			table.insert(lines, i..self:value(ln))
		end
		if inc then self._indent = self._indent - inc end
		return table.concat(lines, "\n")
	end,
	assign = function(self, node)
		local _, names, values = unpack(node)

		return "local "..table.concat(names, ", ").." = "..table.concat(map(values, bind(self, "value")), ", ")
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
		if not fn then error("Unknown op: "..tostring(op)) end
		table.insert(buff, compilers[op](compilers, line))
	end

	return table.concat(buff, "\n")
end


