
module("moonscript.util", package.seeall)

moon = {
	is_object = function(value)
		return type(value) == "table" and value.__class
	end,
	type = function(value)
		base_type = type(value)
		if base_type == "table" then
			cls = value.__class
			if cls then return cls end
		end
		return base_type
	end
}

-- shallow copy
function clone(tbl)
	local out = {}
	for k,v in pairs(tbl) do
		out[k] = v
	end
	return out
end

function map(tbl, fn)
	local out = {}
	for i,v in ipairs(tbl) do
		out[i] = fn(v)
	end
	return out
end

function every(tbl, fn)
	for i=1,#tbl do
		local pass
		if fn then
			pass = fn(tbl[i])
		else
			pass = tbl[i]
		end

		if not pass then return false end
	end
	return true
end

function bind(obj, name)
	return function(...)
		return obj[name](obj, ...)
	end
end

function itwos(seq)
	n = 2
	return coroutine.wrap(function()
		for i = 1, #seq-n+1 do
			coroutine.yield(i, seq[i], i+1, seq[i+1])
		end
	end)
end

function reversed(seq)
	return coroutine.wrap(function()
		for i=#seq,1,-1 do
			coroutine.yield(i, seq[i])
		end
	end)
end

function dump(what)
	local seen = {}
	local function _dump(what, depth)
		depth = depth or 0
		local t = type(what)

		if t == "string" then
			return '"'..what..'"\n'
		elseif t == "table" then
			if seen[what] then 
				return "recursion("..tostring(what)..")...\n"
			end
			seen[what] = true

			depth = depth + 1
			out = "{\n"
			for k,v in pairs(what) do
				out = out..(" "):rep(depth*4).."["..tostring(k).."] = ".._dump(v, depth)
			end

			seen[what] = false

			return out .. (" "):rep((depth-1)*4) .. "}\n"
		else
			return tostring(what).."\n"
		end
	end

	return _dump(what)
end

function split(str, delim)
	if str == "" then return {} end
	str = str..delim
	local out = {}
	for m in str:gmatch("(.-)"..delim) do
		table.insert(out, m)
	end
	return out
end


function trim(str)
	return str:match("^%s*(.-)%s*$")
end


