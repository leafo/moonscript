
module("moonscript.compile", package.seeall)
require "util"

local data = require "moonscript.data"

-- this doesn't work
-- setmetatable(_M, {
-- 	__call = setfenv(function(self, ...)
-- 		compile(...)
-- 	end, _G)
-- })

local map, bind, itwos = util.map, util.bind, util.itwos
local Stack = data.Stack

local indent_char = "  "

function ntype(node)
	if type(node) ~= "table" then return "value" end
	return node[1]
end

local compiler_index = {
	push = function(self) self._scope:push{} end,
	pop = function(self) self._scope:pop() end,

	indent = function(self, amount)
		self._indent = self._indent + amount
	end,

	has_name = function(self, name)
		for i = #self._scope,1,-1 do
			if self._scope[i][name] then return true end
		end
		return false
	end,

	put_name = function(self, name)
		self._scope:top()[name] = true
	end,

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
		self:push()

		for _, arg_name in ipairs(args) do
			self:put_name(arg_name)
		end

		args = table.concat(args, ",")

		local out
		if #block == 0 then
			out = ("function(%s) end"):format(args)
		elseif #block == 1 then
			out = ("function(%s) %s end"):format(args, self:value(block[1]))
		else
			out = ("function(%s)\n%s\n%send"):format(
				args, self:block(block, 1), self:ichar())
		end

		self:pop()
		return out
	end,

	["if"] = function(self, node)
		local _, cond, block = unpack(node)
		return ("if %s then\n%s\n%send"):format(
			self:value(cond), self:block(block, 1), self:ichar())
	end,

	block = function(self, node, inc)
		self:push()
		if inc then self:indent(inc) end

		local lines = {}
		local i = self:ichar()
		for _, ln in ipairs(node) do
			table.insert(lines, i..self:value(ln))
		end
		if inc then self:indent(-inc) end
		self:pop()

        -- add semicolons where they might be needed
        for i, left, k, right in itwos(lines) do
            if left:sub(-1) == ")" and right:sub(1,1) == "(" then
                lines[i] = lines[i]..";"
            end
        end

		return table.concat(lines, "\n")
	end,

	table = function(self, node)
		local _, items = unpack(node)

		self:indent(1)
		local item_values = {}
		for _, item in ipairs(items) do
			local key = self:value(item[1])
			if type(item[1]) ~= "string" then
				key = ("[%s]"):format(key)
			end

			table.insert(item_values, key.." = "..self:value(item[2]))
		end
		local i = self:ichar()
		self:indent(-1)

		if #item_values > 3 then
			return ("{\n%s%s\n%s}"):format(i, table.concat(item_values, ",\n"..i), self:ichar())
		end

		return "{ "..table.concat(item_values, ", ").." }"
	end,

	assign = function(self, node)
		local _, names, values = unpack(node)
		local assigns, current = {}, nil

		local function append(t, name, value)
			if not current or t ~= current[1] then
				current = {t, {name}, {value}}
				table.insert(assigns, current)
			else
				table.insert(current[2], name)
				table.insert(current[3], value)
			end
		end

		for i, assignee in ipairs(names) do
			local name_value = self:value(assignee)
			local value = self:value(values[i])

			if ntype(assignee) == "chain" or self:has_name(assignee) then
				append("non-local", name_value, value)
			else
				append("local", name_value, value)
			end

			if type(assignee) == "string" then
				self:put_name(assignee)
			end
		end

		local lines = {}
		for _, group in ipairs(assigns) do
			local t, names, values = unpack(group)
			if #values == 0 then values = {"nil"} end
			local line = table.concat(names, ", ").." = "..table.concat(values, ", ")
			table.insert(lines, t == "local" and "local "..line or line)
		end
		return table.concat(lines, "\n"..self:ichar())
	end,

	exp = function(self, node)
		local values = {}
		for i = 2, #node do
			table.insert(values, self:value(node[i]))
		end
		return table.concat(values, " ")
	end,

    parens = function(self, node)
        local _, value = unpack(node)
        return '('..self:value(value)..')'
    end,

	string = function(self, node)
		local _, delim, inner, delim_end = unpack(node)
		return delim..inner..(delim_end or delim)
	end,

	value = function(self, node)
		if type(node) == "table" then 
			local fn = self[node[1]]
			if not fn then
				error("Unknown op: "..tostring(node[1]))
			end
			return fn(self, node)
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

function build_compiler()
	return setmetatable({
		_indent = 0,
		_scope = Stack({}),
	}, { __index = compiler_index })
end

function tree(tree)
	local compiler = build_compiler()
    return compiler:block(tree)
end


