#!/usr/bin/lua

module("moonscript", package.seeall)

require "moonscript.parse"
require "moonscript.compile2"
require "moonscript.util"

require "alt_getopt"

local opts, ind = alt_getopt.get_opts(arg, "hbto:", { help = "h" })

local help = [[Usage: %s [options] file...

    -h          Print this message
    -t          Dump parse tree
    -b          Dump time to parse and compile
    -o fname    Write output to file
]]

local gettime = nil
pcall(function()
	require "socket"
	gettime = socket.gettime
end)

function format_time(time)
	return ("%.3fms"):format(time*1000)
end

function print_help(err)
	if err then print("Error: "..err) end
	print(help:format(arg[0]))
	os.exit()
end

function read_file(fname)
	local f = io.open(fname)
	if not f then return nil end
	return f:read("*a")
end

local files = {}
for i = ind, #arg do
	table.insert(files, arg[i])
end

if opts.h then print_help() end
if #files == 0 then
	print_help"Missing input file"
end

local fname = files[1]

local file_str = read_file(fname)
if not file_str then
	print_help("Failed to find file `"..fname.."`")
end


local start_parse = gettime()
local tree, err = parse.string(file_str)
local parse_time = gettime() - start_parse

if not tree then
	print("Parse error: "..err)
	os.exit()
end

if opts.t then
	print(dump.tree(tree))
	os.exit()
end

local start_compile = gettime()
local code = compile.tree(tree)
local compile_time = gettime() - start_compile

if opts.b then
	print("Parse time  ", format_time(parse_time))
	print("Compile time", format_time(compile_time))
else
	if opts.o then
		io.open(opts.o, "w"):write(code.."\n")
	else
		print(code)
	end
end


