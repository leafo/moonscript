#!/usr/bin/lua

module("moonscript", package.seeall)

require "moonscript.parse"
require "moonscript.compile"
require "moonscript.util"

require "alt_getopt"

local opts, ind = alt_getopt.get_opts(arg, "hto:", { help = "h" })

local help = [[Usage: %s [options] file...

    -h          Print this message
    -t          Dump parse tree
    -o fname    Write output to file
]]

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

local tree, err = parse.string(file_str)

if not tree then
	print("Parse error: "..err)
	os.exit()
end

if opts.t then
	print(dump.tree(tree))
	os.exit()
end

local code = compile.tree(tree)
if opts.o then
	io.open(opts.o, "w"):write(code.."\n")
else
	print(code)
end


