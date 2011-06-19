
module("moonscript.data", package.seeall)

local stack_t = {}
local _stack_mt = { __index = stack_t, __tostring = function(self)
	return "<Stack {"..table.concat(self, ", ").."}>"
end}

function stack_t:pop()
	return table.remove(self)
end

function stack_t:push(value)
	table.insert(self, value)
	return value
end

function stack_t:top()
	return self[#self]
end

function Stack(...)
	local self = setmetatable({}, _stack_mt)

	for _, v in ipairs{...} do
		self:push(v)
	end

	return self
end

function Set(items)
	local self = {}
	for _,item in ipairs(items) do
		self[item] = true
	end
	return self
end

-- find out the type of a node
function ntype(node)
	if type(node) ~= "table" then return "value" end
	return node[1]
end

lua_keywords = Set{
	'and', 'break', 'do', 'else', 'elseif',
	'end', 'false', 'for', 'function', 'if',
	'in', 'local', 'nil', 'not', 'or',
	'repeat', 'return', 'then', 'true',
	'until', 'while'
}
