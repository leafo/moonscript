#!/usr/bin/lua

module("moonscript", package.seeall)

require "moonscript.parse"
require "moonscript.compile"
require "moonscript.util"

require "alt_getopt"

require "lpeg"

-- moonloader and repl
local opts, ind = alt_getopt.get_opts(arg, "chd", { help = "h" })

local help = [=[Usage: %s [options] [script [args]]

    -c          Compile in memory, don't write .lua files
    -h          Print this message
    -d          Disable stack trace rewriting
]=]

local function print_help(err)
	if err then print("Error: "..err) end
	print(help:format(arg[0]))
	os.exit()
end

if opts.h then print_help() end

local script = arg[ind]
if not script then
	print_help("repl not yet supported")
	return
end

local dirsep = "/"
local function create_moonpath(package_path)
	local paths = util.split(package_path, ";")
	for i=1,#paths do
		local p = paths[i]:match("^(.-)%.lua$")
		if p then
			paths[i] = p..".moon"
		end
	end
	return table.concat(paths, ";")
end

local line_tables = {}
local function moon_chunk(file, file_path)
	local text = file:read"*a"
	local tree, err = parse.string(text)
	if not tree then error("Parse error: "..err) end
	local code, ltable, pos = compile.tree(tree)
	if not code then
		error(compile.format_error(ltable, pos, text))
	end

	line_tables[file_path] = ltable

	return load(function()
		local out = code
		code = nil
		return out
	end, file_path)
end

local function moon_loader(name)
	name_path = name:gsub("%.", dirsep)
	paths = util.split(package.moonpath, ";")

	local file, file_path
	for i=1,#paths do
		file_path = paths[i]:gsub("?", name_path)
		file = io.open(file_path)
		if file then break end
	end

	if not file then 
		return nil, "Could not find moon file"
	end

	return moon_chunk(file, file_path)
end

if not package.moonpath then
	package.moonpath = create_moonpath(package.path)
end

table.insert(package.loaders, 2, moon_loader)

local lookup_text = {}
local function lookup_line(fname, pos)
	if not lookup_text[fname] then
		local f = io.open(fname)
		lookup_text[fname] = f:read"*a"
		f:close()
	end

	local sub = lookup_text[fname]:sub(1, pos)
	local count = 1
	for _ in sub:gmatch("\n") do
		count = count + 1
	end
	return count
end

local function reverse_line(fname, line_table, line)
	for i = line,0,-1 do
		if line_table[i] then
			return lookup_line(fname, line_table[i])
		end
	end
	return "unknown"
end

local function rewrite_traceback(text, err)
	local header_text = "stack traceback:"

	local Header, Line = lpeg.V"Header", lpeg.V"Line"
	local Break = lpeg.S"\n"
	local g = lpeg.P {
		Header,
		Header = header_text * Break * lpeg.Ct(Line^1),
		Line = "\t" * lpeg.C((1 -Break)^0) * (Break + -1)
	}

	local function rewrite_single(trace)
		local fname, line, msg = trace:match('^%[string "(.-)"]:(%d+): (.*)$')
		if fname then
			if line_tables[fname] then
				local table = line_tables[fname]
				return fname .. ":" ..  reverse_line(fname, table, line) .. ": " .. msg
			end
		end
	end


	err = rewrite_single(err)
	local match = g:match(text)
	for i, trace in pairs(match) do
		match[i] = rewrite_single(trace)
	end

	return table.concat({
		"moon: "..err,
		header_text,
		"\t" .. table.concat(match, "\n\t")
	}, "\n")
end

local file, err = io.open(script)
if not file then error(err) end

local new_arg = {
	[-1] = arg[0],
	[0] = arg[ind],
	select(ind + 1, unpack(arg))
}

local chunk = moon_chunk(file, script)
getfenv(chunk).arg = new_arg

local runner = coroutine.create(chunk)
local success, err = coroutine.resume(runner, unpack(new_arg))
if not success then
	local trace = debug.traceback(runner)
	if not opts.d then
		print(rewrite_traceback(trace, err))
	else
		print(trace)
	end
end
