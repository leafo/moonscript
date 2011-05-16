
module("util", package.seeall)

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


