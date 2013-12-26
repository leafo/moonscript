package = "moonscript"
version = "dev-1"

source = {
	url = "git://github.com/leafo/moonscript.git"
}

description = {
	summary = "A programmer friendly language that compiles to Lua",
	homepage = "http://moonscript.org",
	maintainer = "Leaf Corcoran <leafot@gmail.com>",
	license = "MIT"
}

dependencies = {
	"lua >= 5.1",
	"lpeg >= 0.10, ~= 0.11",
	"alt-getopt >= 0.7",
	"luafilesystem >= 1.5"
}

build = {
	type = "builtin",
	modules = {
		["moon"] = "moon/init.lua",
		["moon.all"] = "moon/all.lua",
		["moonscript"] = "moonscript/init.lua",
		["moonscript.base"] = "moonscript/base.lua",
		["moonscript.cmd.coverage"] = "moonscript/cmd/coverage.lua",
		["moonscript.cmd.lint"] = "moonscript/cmd/lint.lua",
		["moonscript.compile"] = "moonscript/compile.lua",
		["moonscript.compile.statement"] = "moonscript/compile/statement.lua",
		["moonscript.compile.value"] = "moonscript/compile/value.lua",
		["moonscript.data"] = "moonscript/data.lua",
		["moonscript.dump"] = "moonscript/dump.lua",
		["moonscript.errors"] = "moonscript/errors.lua",
		["moonscript.line_tables"] = "moonscript/line_tables.lua",
		["moonscript.parse"] = "moonscript/parse.lua",
		["moonscript.transform"] = "moonscript/transform.lua",
		["moonscript.transform.destructure"] = "moonscript/transform/destructure.lua",
		["moonscript.transform.names"] = "moonscript/transform/names.lua",
		["moonscript.types"] = "moonscript/types.lua",
		["moonscript.util"] = "moonscript/util.lua",
		["moonscript.version"] = "moonscript/version.lua",
	},
	install = {
		bin = { "bin/moon", "bin/moonc" }
	}
}

