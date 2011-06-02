
module("moonscript.compile", package.seeall)

local util = require "moonscript.util"
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

-- number of newlines in string
local function num_lines(str)
	local sum = 0
	for v in str:gmatch("[\n]") do
		sum = sum + 1
	end
	return sum
end

-- small enough to fit on one line
local function is_small(str)
	return num_lines(str) == 0 and #str < 40
end

-- functions that can be inlined, or called from build in library
local moonlib = {
	bind = function(tbl, name)
		return table.concat{"moon.bind(", tbl, ".",
			name, ", ", tbl, ")"}
	end
}

-- these are always expressions, never statements, must be sent into temp variable
local must_return = data.Set{ 'parens', 'exp', 'value', 'string', 'table', 'fndef', 'explist' }

-- these can't return a value, and must be munged
local block_statements = data.Set{ 'if' }

-- make sure there are no block levels statements in expression
local function validate_expression(block)
	-- need to annotate blocks? how do I know where expressions are
end

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

		-- importing from constant expression
		if type(source) == "string" then
			local values = get_values(source)
			return table.concat({"local", table.concat(final_names, ", "),
				"=", table.concat(values, ", ")}, " ")
		end

		local tmp_name = self:get_free_name("table")

		self:push()
		self:put_name(tmp_name)
		inner = { "local "..tmp_name.." = "..self:value(source) }

		for i, value in ipairs(get_values(tmp_name)) do
			table.insert(inner, final_names[i].." = "..value)
		end
		self:pop()

		return self:pretty{
			"local "..table.concat(final_names, ", "),
			"do", inner, "end"
		}
	end,

	fndef = function(self, node)
		local _, args, arrow, block = unpack(node)
		self:push()

		for _, arg_name in ipairs(args) do
			self:put_name(arg_name)
		end

		if arrow == "fat" then table.insert(args, 1, "self") end
		args = table.concat(args, ",")

		local out
		if #block == 0 then
			out = ("function(%s) end"):format(args)
		else
			local inner = self:block(block, true)
			if #inner == 1 and is_small(inner[1]) then
				out = ("function(%s) %s end"):format(args, inner[1])
			else
				out = self:pretty{
					("function(%s)"):format(args),
					inner,
					"end"
				}
			end
		end

		self:pop()
		return out
	end,

	-- compile if
	["if"] = function(self, node, return_value)
		local cond, block = node[2], node[3]

		local out = {
			("if %s then"):format(self:value(cond)),
			self:block(block, return_value)
		}

		for i = 4,#node do
			local clause = node[i]
			local block
			if clause[1] == "else" then
				table.insert(out, "else")
				block = clause[2]
			elseif clause[1] == "elseif" then
				table.insert(out, "elseif "..self:value(clause[2]).." then")
				block = clause[3]
			else
				error("Unknown if clause: "..clause[1])
			end
			table.insert(out, self:block(block, return_value))
		end

		table.insert(out, "end")
		
		return self:pretty(out)
	end,

	['while'] = function(self, node)
		local _, cond, block = unpack(node)

		return self:pretty{
			("while %s do"):format(self:value(cond)),
			self:block(block),
			"end"
		}
	end,

	name_list = function(self, node)
		return table.concat(self:values(node), ", ")
	end,

	-- need to get tmp name instead of using tmp
	comprehension = function(self, node, return_value)
		local _, exp, clauses = unpack(node)

		local action = return_value
			and { ("table.insert(tmp, %s)"):format(self:value(exp)) }
			or { self:stm(exp) }

		self:push()
		for i = #clauses,1,-1 do
			local c = clauses[i]

			if "for" == c[1] then
				local _, names, iter = unpack(c)
				if ntype(iter) == "unpack" then
					iter = iter[2]
					local items_tmp, index_tmp = self:get_free_name("items"), self:get_free_name("index")

					self:put_name(items_tmp)
					self:put_name(index_tmp)

					action = {
						("local %s = %s"):format(items_tmp, self:value(iter)),
						("for %s=1,#%s do"):format(index_tmp, items_tmp),
						{("local %s = %s[%s]"):format(self:name_list(names), items_tmp, index_tmp)},
						action,
						"end"
					}
				else
					action = {
						("for %s in %s do"):format(self:name_list(names), self:value(iter)),
						action,
						"end"
					}
				end
			elseif "when" == c[1] then
				local _, when = unpack(c)
				action = {
					("if %s then"):format(self:value(when)),
					action,
					"end"
				}
			else
				error("Unknown clause type :"..tostring(c[1]))
			end
		end
		self:pop()

		if return_value then
			return self:pretty{
				"(function()",
					{ "local tmp = {}", },
					action,
					{ "return tmp" },
				"end)()"
			}
		else
			return self:pretty(action)
		end
	end,

	-- returns list of compiled statements
	block = function(self, node, return_value, inc)
		inc = inc or 1

		self:push()
		self:indent(inc)

		local lines = {}
		local len = #node
		for i=1,len do
			local ln = node[i]
			local value = self:stm(ln, i == len and return_value)
			if type(value) == "table" then
				for _, v in ipairs(value) do
					table.insert(lines, v)
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

		self:indent(-inc)
		self:pop()

		return lines
	end,

	table = function(self, node)
		local _, items = unpack(node)

		self:indent(1)
		local len = #items
		local item_values = {}
		for i = 1,len do
			local item = items[i]
			local item_value
			if #item == 1 then
				item_value = self:value(item[1])
			else
				local key = self:value(item[1])
				if type(item[1]) ~= "string" then
					key = ("[%s]"):format(key)
				end

				item_value = key.." = "..self:value(item[2])
			end

			if i ~= len then
				item_value = item_value..","
			end

			table.insert(item_values, item_value)
		end
		self:indent(-1)

		if #item_values > 3 then
			return self:pretty{ "{", item_values, "}" }
		end

		return "{ "..table.concat(item_values, " ").." }"
	end,

	assign = function(self, node)
		local _, names, values = unpack(node)

		-- declare undeclared names
		local undeclared_names = {}
		for _, name in ipairs(names) do
			if type(name) == "string" and not self:has_name(name) then
				table.insert(undeclared_names, name)
				self:put_name(name)
			end
		end

		local compact = not block_statements[ntype(values)] and #undeclared_names == #names

		local lines = {}
		local num_undeclared = #undeclared_names
		if num_undeclared > 0 and not compact then
			table.insert(lines, "local "..table.concat(undeclared_names, ", "))
		end

		if block_statements[ntype(values)] then
			table.insert(lines, self:stm(values, self:name_list(names)))
		else
			local ln = self:name_list(names).." = "..table.concat(self:values(values), ", ")

			if compact then
				ln = "local "..ln
			end

			table.insert(lines, ln)
		end

		return self:pretty(lines)
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

	explist = function(self, node)
		local values = {}
		for i=2,#node do
			table.insert(values, self:value(node[i]))
		end
		return table.concat(values, ", ")
	end,

	value = function(self, node, return_value, ...)
		if return_value == nil then return_value = true end

		if type(node) == "table" then 
			local fn = self[node[1]]
			if not fn then
				error("Unknown op: "..tostring(node[1]))
			end
			return fn(self, node, return_value, ...)
		end

		return node
	end,

    -- has no return value, meant to be on line of it's own
    stm = function(self, node, return_value)
        local value = self:value(node, return_value)

		local is_value = must_return[ntype(node)] 
		local ret_chain = ntype(node) == "chain" and node[2] ~= "return"

		if return_value and (is_value or ret_chain) then
			local return_to = "return"
			if type(return_value) == "string" then
				return_to = return_value.." ="
			end

			return return_to.." "..value
		elseif is_value then
			return self:value({"assign", {"_"}, {value}}, false)
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
    return compiler:pretty(compiler:block(tree, false, 0))
end


