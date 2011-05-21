
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

function ntype(node)
	if type(node) ~= "table" then return "value" end
	return node[1]
end

local compilers = {
	_indent = 0,
	ichar = function(self)
		return indent_char:rep(self._indent)
	end,

	chain = function(self, node)
		local callee = node[2]
		local actions = {}
		for i = 3,#node do
			local t, arg = unpack(node[i])
			if t == "call" then
				table.insert(actions, "("..table.concat(self:values(arg), ', ')..")")
			elseif t == "index" then
				table.insert(actions, "["..self:value(arg).."]")
			else
				error("Unknown chain action: "..t)
			end
		end

		local callee_value = self:value(callee)
		if ntype(callee) == "exp" then
			callee_value = "("..callee_value..")"
		end

		return callee_value..table.concat(actions)
	end,

	fndef = function(self, node)
		local _, args, block = unpack(node)
		if #block == 0 then
			return "function() end"
		elseif #block == 1 then
			return ("function(%s) %s end"):format(
				table.concat(args, ", "), self:value(block[1]))
		end
		return ("function(%s)\n%s\n%send"):format(
			table.concat(args, ", "), self:block(block, 1), self:ichar())
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
		return "local "..table.concat(names, ", ").." = "..table.concat(self:values(values), ", ")
	end,

	exp = function(self, node)
		local values = {}
		for i = 2, #node do
			table.insert(values, self:value(node[i]))
		end
		return table.concat(values, " ")
	end,

	value = function(self, node)
		if type(node) == "table" then 
			local op = unpack(node)
			return self[op](self, node)
		end

		return node
	end,

	-- a list of values
	values = function(self, items, start)
		start = start or 1
		local compiled = {}
		for i = start,#items do
			table.insert(compiled, self:value(items[i]))
		end
		return compiled
	end
}

_M.tree = function(tree)
	local buff = {}
	for _, line in ipairs(tree) do
		local op = type(line) == "table" and line[1] or "value"
		local fn = compilers[op]
		if not fn then error("Unknown op: "..tostring(op)) end
		table.insert(buff, compilers[op](compilers, line))
	end

	return table.concat(buff, "\n")
end


