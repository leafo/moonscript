local moonscript = require "moonscript.base"

local util = require "moonscript.util"
local errors = require "moonscript.errors"

local unpack = util.unpack


local function print_err(...)
	local msg = table.concat({...}, "\t")
	io.stderr:write(msg .. "\n")
end

return {
    load = function(script_fname, opts, args)
        local moonscript_chunk, lua_parse_error
        local passed, err = pcall(function()
        	moonscript_chunk, lua_parse_error = moonscript.loadfile(script_fname, { implicitly_return_root = false })
        end)

        if not passed then
        	print_err(err)
        	os.exit(1)
        end

        if not moonscript_chunk then
        	if lua_parse_error then
        		print_err(lua_parse_error)
        	else
        		print_err("Can't find file: " .. script_fname)
        	end
        	os.exit(1)
        end

        util.getfenv(moonscript_chunk).arg = args

        local function run_chunk()
        	moonscript.insert_loader()
        	moonscript_chunk(unpack(args))
        	moonscript.remove_loader()
        end

        if not opts.d then
        	local err, trace
        	local cov

        	if opts.c then
        		local coverage = require "moonscript.cmd.coverage"
        		cov = coverage.CodeCoverage()
        		cov:start()
        	end

        	xpcall(run_chunk, function(_err)
        		err = _err
        		trace = debug.traceback("", 2)
        	end)

        	if err then
        		local truncated = errors.truncate_traceback(util.trim(trace))
        		local rewritten = errors.rewrite_traceback(truncated, err)

        		if rewritten then
        			print_err(rewritten)
        		else
        			-- faield to rewrite, show original
        			print_err(table.concat({
        				err,
        				util.trim(trace)
        			}, "\n"))
        		end
        	else
        		if cov then
        			cov:stop()
        			cov:print_results()
        		end
        	end
        else
        	run_chunk()
        end
            
    end
}
