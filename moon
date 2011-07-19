#!/usr/bin/lua

require "alt_getopt"
require "moonscript.errors"
require "moonscript"


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

local script_fname = arg[ind]
if not script_fname then
	print_help("repl not yet supported")
	return
end

local file, err = io.open(script_fname)
if not file then error(err) end

local new_arg = {
	[-1] = arg[0],
	[0] = arg[ind],
	select(ind + 1, unpack(arg))
}

local chunk = moonscript.moon_chunk(file, script_fname)
getfenv(chunk).arg = new_arg

local runner = coroutine.create(chunk)
local success, err = coroutine.resume(runner, unpack(new_arg))
if not success then
	local trace = debug.traceback(runner)
	if not opts.d then
		print(moonscript.errors.rewrite_traceback(trace, err))
	else
		print(trace)
	end
end
