require "lfs"

local argv = {...}
local action = table.remove(argv, 1) or "run"

local diff_tool = "diff"

local opts = {
	in_dir = "tests/inputs",
	out_dir = "tests/outputs",
	input_pattern = "(.*)%.moon$",
	output_ext = ".lua"
}

local function diff(a_fname, b_fname)
	return io.popen(diff_tool.." ".. a_fname.." "..b_fname, "r"):read("*a")
end

local function input_name(name) return opts.in_dir .. "/" .. name end
local function output_name(name)
	return opts.out_dir.."/"..name:match(opts.input_pattern)..opts.output_ext 
end

local function run_file(name) 
	name = input_name(name)
	file_str = io.open(name):read("*a")

	local parse = require "moonscript.parse"
	local compile = require "moonscript.compile"

	return compile.tree(parse.string(file_str))
end

local function inputs(pattern)
	return coroutine.wrap(function()
		for file in lfs.dir(opts.in_dir) do
			local body = file:match(opts.input_pattern)
			if body then
				if not pattern or body:match(pattern) then
					coroutine.yield(file)
				end
			end
		end
	end)
end

local actions = {
	build = function(pattern)
		for file in inputs(pattern) do
			local out_fname = output_name(file)
			print("Building: ", file, out_fname)
			io.open(out_fname, "w"):write(run_file(file))
		end
	end,
	run = function(pattern) 
		local tests_run, result = 0
		for file in inputs(pattern) do
			tests_run = tests_run + 1
			local correct_fname = output_name(file)
			result = run_file(file)
			local handle = io.open(correct_fname)

			if not handle then 
				print("Test not built yet:", correct_fname)
			else 
				local correct = handle:read("*a")
				if result ~= correct then
					print("Test", file, "failed")
					local tmp_name = os.tmpname()
					local tmp = io.open(tmp_name, "w")
					tmp:write(result)
					tmp:close()
					print(diff(correct_fname, tmp_name))
					os.remove(tmp_name)
					-- break
				else
					print("Test", file, "passed")
				end
			end
		end

		if tests_run == 0 then
			if not pattern then
				print("No tests found")
			else
				print("No tests matching pattern:", pattern)
			end
		elseif tests_run == 1 then
			print(result)
		end
	end,
	list = function(pattern) 
		local count = 0
		for file in inputs(pattern) do
			count = count + 1
			print(file)
		end
		if count > 0 then print("") end
		print("Count:", count)
	end
}

local fn = actions[action]
if fn then
	fn(unpack(argv))
else
	print("Unknown action:", action)
end


