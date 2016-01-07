#!/usr/bin/env lua

local alt_getopt = require "alt_getopt"
local lfs = require "lfs"

local opts, ind = alt_getopt.get_opts(arg, "lvhwt:o:pTXb", {
	print = "p", tree = "T", version = "v", help = "h", lint = "l"
})

local read_stdin = arg[1] == "--"

local polling_rate = 1.0

local help = [[Usage: %s [options] files...

    -h          Print this message
    -w          Watch file/directory
    -t path     Specify where to place compiled files
    -o file     Write output to file
    -p          Write output to standard out
    -T          Write parse tree instead of code (to stdout)
    -X          Write line rewrite map instead of code (to stdout)
    -l          Perform lint on the file instead of compiling
    -b          Dump parse and compile time (doesn't write output)
    -v          Print version

    --          Read from standard in, print to standard out
                (Must be first and only argument)
]]

if opts.v then
	local v = require "moonscript.version"
	v.print_version()
	os.exit()
end

function print_help(err)
	local help_msg = help:format(arg[0])

	if err then
		io.stderr:write("Error: ".. err .. "\n")
		io.stderr:write(help_msg .. "\n")
		os.exit(1)
	else
		print(help_msg)
		os.exit(0)
	end
end

function log_msg(...)
	if not opts.p then
		io.stderr:write(table.concat({...}, " ") .. "\n")
	end
end

local moonc = require("moonscript.cmd.moonc")
local util = require "moonscript.util"
local mkdir = moonc.mkdir
local normalize_dir = moonc.normalize_dir
local parse_dir = moonc.parse_dir
local parse_file = moonc.parse_file
local compile_and_write = moonc.compile_and_write
local path_to_target = moonc.path_to_target

local function scan_directory(root, collected)
	root = normalize_dir(root)
	collected = collected or {}

	for fname in lfs.dir(root) do
		if not fname:match("^%.") then
			local full_path = root..fname

			if lfs.attributes(full_path, "mode") == "directory" then
				scan_directory(full_path, collected)
			end

			if fname:match("%.moon$") then
				table.insert(collected, full_path)
			end
		end
	end

	return collected
end

local function remove_dups(tbl, key_fn)
	local hash = {}
	local final = {}

	for _, v in ipairs(tbl) do
		local dup_key = key_fn and key_fn(v) or v
		if not hash[dup_key] then
			table.insert(final, v)
			hash[dup_key] = true
		end
	end

	return final
end

-- creates tuples of input and target
local function get_files(fname, files)
	files = files or {}

	if lfs.attributes(fname, "mode") == "directory" then
		for _, sub_fname in ipairs(scan_directory(fname)) do
			table.insert(files, {
				sub_fname,
				path_to_target(sub_fname, opts.t, fname)
			})
		end
	else
		table.insert(files, {
			fname,
			path_to_target(fname, opts.t)
		})
	end

	return files
end

if opts.h then
	print_help()
end

if read_stdin then
	local parse = require "moonscript.parse"
	local compile = require "moonscript.compile"

	local text = io.stdin:read("*a")
	local tree, err = parse.string(text)

	if not tree then error(err) end
	local code, err, pos = compile.tree(tree)

	if not code then
		error(compile.format_error(err, pos, text))
	end

	print(code)
	os.exit()
end

local inputs = {}
for i = ind, #arg do
	table.insert(inputs, arg[i])
end

if #inputs == 0 then
	print_help("No files specified")
end

local files = {}
for _, input in ipairs(inputs) do
	get_files(input, files)
end

files = remove_dups(files, function(f)
	return f[2]
end)

if opts.o and #files > 1 then
	print_help("-o can not be used with multiple input files")
end

local function get_sleep_func()
	local sleep
	if not pcall(function()
		local socket = require "socket"
		sleep = socket.sleep
	end) then
		-- This is set by moonc.c in windows binaries
		sleep = require("moonscript")._sleep
	end
	if not sleep then
		error("Missing sleep function; install LuaSocket")
	end
	return sleep
end

local function plural(count, word)
	if count ~= 1 then
		word = word .. "s"
	end
	return table.concat({count, word}, " ")
end

-- returns an iterator that returns files that have been updated
local function create_watcher(files)
	local msg = "Starting watch loop (Ctrl-C to exit)"

	local inotify
	pcall(function()
		inotify = require "inotify"
	end)

	if inotify then
		local dirs = {}

		for _, tuple in ipairs(files) do
			local dir = parse_dir(tuple[1])
			if dir == "" then
				dir = "./"
			end
			table.insert(dirs, dir)
		end

		dirs = remove_dups(dirs)

		return coroutine.wrap(function()
			io.stderr:write(("%s with inotify [%s]"):format(msg, plural(#dirs, "dir")) .. "\n")

			local wd_table = {}
			local handle = inotify.init()
			for _, dir in ipairs(dirs) do
				local wd = handle:addwatch(dir, inotify.IN_CLOSE_WRITE, inotify.IN_MOVED_TO)
				wd_table[wd] = dir
			end

			while true do
				local events = handle:read()
				if not events then
					break
				end

				for _, ev in ipairs(events) do
					local fname = ev.name
					if fname:match("%.moon$") then
						local dir = wd_table[ev.wd]
						if dir ~= "./" then
							fname = dir .. fname
						end
						-- TODO: check to make sure the file was in the original set
						coroutine.yield(fname)
					end
				end
			end
		end)
	else
		-- poll the filesystem instead
		local sleep = get_sleep_func()
		return coroutine.wrap(function()
			io.stderr:write(("%s with polling [%s]"):format(msg, plural(#files, "file")) .. "\n")

			local mod_time = {}
			while true do
				for _, tuple in ipairs(files) do
					local file = tuple[1]
					local time = lfs.attributes(file, "modification")
					if not mod_time[file] then
						mod_time[file] = time
					else
						if time ~= mod_time[file] then
							if time > mod_time[file] then
								coroutine.yield(file)
								mod_time[file] = time
							end
						end
					end
				end
				sleep(polling_rate)
			end
		end)
	end
end


if opts.w then
	-- build function to check for lint or compile in watch
	local handle_file
	if opts.l then
		local lint = require "moonscript.cmd.lint"
		handle_file = lint.lint_file
	else
		handle_file = compile_and_write
	end

	local watcher = create_watcher(files)
	-- catches interrupt error for ctl-c
	local protected = function()
		local status, file = true, watcher()
		if status then
			return file
		elseif file ~= "interrupted!" then
			error(file)
		end
	end

	for fname in protected do
		local target = path_to_target(fname, opts.t)

		if opts.o then
			target = opts.o
		end

		local success, err = handle_file(fname, target)
		if opts.l then
			if success then
				io.stderr:write(success .. "\n\n")
			elseif err then
				io.stderr:write(fname .. "\n" .. err .. "\n\n")
			end
		elseif not success then
			io.stderr:write(table.concat({
				"",
				"Error: " .. fname,
				err,
				"\n",
			}, "\n"))
		elseif success == "build" then
			log_msg("Built", fname, "->", target)
		end
	end

	io.stderr:write("\nQuitting...\n")
elseif opts.l then
	local has_linted_with_error;
	local lint = require "moonscript.cmd.lint"
	for _, tuple in pairs(files) do
		local fname = tuple[1]
		local res, err = lint.lint_file(fname)
		if res then
			has_linted_with_error = true
			io.stderr:write(res .. "\n\n")
		elseif err then
			has_linted_with_error = true
			io.stderr:write(fname .. "\n" .. err.. "\n\n")
		end
	end
	if has_linted_with_error then
		os.exit(1)
	end
else
	for _, tuple in ipairs(files) do
		local fname, target = util.unpack(tuple)
		if opts.o then
			target = opts.o
		end

		local success, err = compile_and_write(fname, target, {
			print = opts.p,
			fname = fname,
			benchmark = opts.b,
			show_posmap = opts.X,
			show_parse_tree = opts.T,
		})

		if not success then
			io.stderr:write(fname .. "\t" .. err .. "\n")
			os.exit(1)
		elseif success == "build" then
			log_msg("Built", fname)
		end
	end
end


