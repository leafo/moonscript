#!/usr/bin/lua

module("moonscript", package.seeall)

require "moonscript.parse"
require "moonscript.compile2"
require "moonscript.util"

require "alt_getopt"

-- moonloader and repl
local opts, ind = alt_getopt.get_opts(arg, "ch", { help = "h" })

local help = [=[Usage: %s [options] [script [args]]

    -c          Compile in memory, don't write .lua files
    -h          Print this message
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

local function moon_chunk(file, file_path)
	-- print("loading", file_path)
	local tree, err = parse.string(file:read"*a")
	if not tree then error("Parse error: "..err) end
	local code = compile.tree(tree)

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

local file, err = io.open(script)
if not file then error(err) end

local new_arg = {
	[-1] = arg[0],
	[0] = arg[ind],
	select(ind + 1, unpack(arg))
}

local chunk = moon_chunk(file, script)
getfenv(chunk).arg = new_arg
chunk(unpack(new_arg))
