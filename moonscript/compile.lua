
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

-- functions that can be inlined, or called from build in library
local moonlib = {
	bind = function(tbl, name)
		return table.concat{"moon.bind(", tbl, ".",
			name, ", ", tbl, ")"}
	end
}

local must_return = data.Set{ 'parens', 'exp', 'value', 'string', 'table', 'fndef' }

local compiler_index = {
	push = function(self) self._scope:push{} end,
	pop = function(self) self._scope:pop() end,

	indent = function(self, amount)
		self._indent = self._indent + amount
	end,

	pretty = function(self, tbl, indent_front)
		local out = {}
		for _, line in ipairs(tbl) do
			if type(line) == "table" then
				self:indent(1)
				table.insert(out, indent_char..self:pretty(line))
				self:indent(-1)
			else
				table.insert(out, line)
			end
		end

		local block = table.concat(out, "\n"..self:ichar())
		if indent_front then
			block = self:ichar()..block
		end
		return block
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

	get_free_name = function(self, basename)
		basename = basename or "moon"
		local i = 0
		local name
		repeat
			name = table.concat({"", basename, i}, "_")
			i = i + 1
		until not self:has_name(name)

		return name
	end,

	ichar = function(self, ...)
		local depths = {...}
		if #depths == 0 then
			return indent_char:rep(self._indent)
		else
			local indents = {}
			for _, v in ipairs(depths) do
				table.insert(indents, indent_char:rep(self._indent+v))
			end
			return unpack(indents)
		end
	end,

	chain_item = function(self, node)
		local t, arg = unpack(node)
		if t == "call" then
			return "("..table.concat(self:values(arg), ', ')..")"
		elseif t == "index" then
			return "["..self:value(arg).."]"
		elseif t == "dot" then
			return "."..arg
		elseif t == "colon" then
			return ":"..arg..self:chain_item(node[3])
		else
			error("Unknown chain action: "..t)
		end
	end,

	chain = function(self, node)
		local callee = node[2]
		local actions = {}

		for i = 3,#node do
			table.insert(actions, self:chain_item(node[i]))
		end

		local callee_value = self:value(callee)
		if ntype(callee) == "exp" then
			callee_value = "("..callee_value..")"
		end

		return callee_value..table.concat(actions)
	end,

	import = function(self, node)
		local _, names, source = unpack(node)

		local to_bind = {}
		local final_names = {}
		for _, name in ipairs(names) do
			if ntype(name) == ":" then
				name = self:value(name[2])
				to_bind[name] = true
			else
				name = self:value(name)
			end

			table.insert(final_names, name)
			self:put_name(name)
		end

		local function get_values(from)
			local values = {}
			for _, name in ipairs(final_names) do
				local v = to_bind[name] and
					moonlib.bind(from, name) or from.."."..name
				table.insert(values, v)
			end
			return values
		end

		if type(source) == "string" then
			local values = get_values(source)
			return table.concat({"local", table.concat(final_names, ", "),
				"=", table.concat(values, ", ")}, " ")
		end

		local outer, inner = self:ichar(0, 1)
		local tmp_name = self:get_free_name("table")
		out = {
			"local "..table.concat(final_names, ", "),
			outer.."do",
			inner.."local "..tmp_name.." = "..self:value(source)
		}

		for i, value in ipairs(get_values(tmp_name)) do
			table.insert(out, inner..final_names[i].." = "..value)
		end

		table.insert(out, outer.."end")
		return table.concat(out, "\n")
	end,

	fndef = function(self, node)
		local _, args, arrow, block = unpack(node)
		self:push()

		for _, arg_name in ipairs(args) do
			self:put_name(arg_name)
		end

		if arrow == "fat" then table.insert(args, "self") end
		args = table.concat(args, ",")

		local out
		if #block == 0 then
			out = ("function(%s) end"):format(args)
		elseif #block == 1 and must_return[ntype(block[1])] then
			out = ("function(%s) %s end"):format(args, self:block(block, true, 0))
		else
			out = ("function(%s)\n%s\n%send"):format(
				args, self:block(block, true), self:ichar())
		end

		self:pop()
		return out
	end,

	-- compile if
	["if"] = function(self, node, return_value)
		local cond, block = node[2], node[3]
		local ichr = self:ichar()

		local out = {
			("if %s then"):format(self:value(cond)),
			self:block(block, return_value)
		}

		for i = 4,#node do
			local clause = node[i]
			local block
			if clause[1] == "else" then
				table.insert(out, ichr.."else")
				block = clause[2]
			elseif clause[1] == "elseif" then
				table.insert(out, ichr.."elseif "..self:value(clause[2]).." then")
				block = clause[3]
			else
				error("Unknown if clause: "..clause[1])
			end
			table.insert(out, self:block(block, return_value))
		end

		table.insert(out, ichr.."end")

		return table.concat(out, "\n")
	end,

	['while'] = function(self, node)
		local _, cond, block = unpack(node)
		local ichr = self:ichar()

		return ("while %s do\n%s\n%send"):format(self:value(cond),
			self:block(block, nil, 1), ichr)
	end,

	name_list = function(self, node)
		return table.concat(self:values(node), ", ")
	end,

	comprehension = function(self, node)
		local _, exp, clauses = unpack(node)
		local insert = { ("table.insert(tmp, %s)"):format(self:value(exp)) }

		for i = #clauses,1,-1 do
			local c = clauses[i]

			if "for" == c[1] then
				local _, names, iter = unpack(c)
				insert = {
					("for %s in %s do"):format(self:name_list(names), self:value(iter)),
					insert,
					"end"
				}
			elseif "when" == c[1] then
				local _, when = unpack(c)
				insert = {
					("if %s then"):format(self:value(when)),
					insert,
					"end"
				}
			else
				error("Unknown clause type :"..tostring(c[1]))
			end
		end

		return self:pretty{
			"(function()",
				{ "local tmp = {}", },
				insert,
				{ "return tmp" },
			"end)()"
		}
	end,

	block = function(self, node, return_value, inc)
		inc = inc or 1

		self:push()
		self:indent(inc)

		local lines = {}
		local len = #node
		for i=1,len do
			local ln = node[i]
			local value = self:stm(ln, return_value and i == len)
			if type(value) == "table" then
				for _, v in value do
					table.insert(lines, value)
				end
			else
				table.insert(lines, value)
			end
		end

        -- add semicolons where they might be needed
        for i, left, k, right in itwos(lines) do
            if left:sub(-1) == ")" and right:sub(1,1) == "(" then
                lines[i] = lines[i]..";"
            end
        end

		local out = self:pretty(lines, true)

		self:indent(-inc)
		self:pop()

		return out
	end,

	table = function(self, node)
		local _, items = unpack(node)

		self:indent(1)
		local item_values = {}
		for _, item in ipairs(items) do
			if #item == 1 then
				table.insert(item_values, self:value(item[1]))
			else
				local key = self:value(item[1])
				if type(item[1]) ~= "string" then
					key = ("[%s]"):format(key)
				end

				table.insert(item_values, key.." = "..self:value(item[2]))
			end
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
			if i % 2 == 1 and node[i] == "!=" then
				node[i] = "~="
			end
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

	value = function(self, node, ...)
		if return_value == nil then return_value = true end

		if type(node) == "table" then 
			local fn = self[node[1]]
			if not fn then
				error("Unknown op: "..tostring(node[1]))
			end
			return fn(self, node, ...)
		end

		return node
	end,

    -- has no return value, meant to be on line of it's own
    stm = function(self, node, return_value)
        local value = self:value(node, return_value)

        if must_return[ntype(node)] then
			if return_value then
				return "return "..value
			else
				return self:value({"assign", {"_"}, {value}}, false)
			end
        end

        return value
    end,

	minus = function(self, node)
		local _, value = unpack(node)
		return "-"..self:value(value)
	end,

	length = function(self, node)
		local _, value = unpack(node)
		return "#"..self:value(value)
	end,

	["not"] = function(self, node)
		local _, value = unpack(node)
		return "not "..self:value(value)
	end,

	self = function(self, node)
		local _, val = unpack(node)
		return "self."..self:value(val)
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
    return compiler:block(tree, false, 0)
end


