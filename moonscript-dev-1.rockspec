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
	"lpeg >= 0.10",
	"alt-getopt >= 0.7",
	"luafilesystem >= 1.5"
}

build = {
	type = "builtin",
	modules = {
		["moonscript.transform.destructure"] = "moonscript/transform/destructure.lua",
		["moonscript.transform.names"] = "moonscript/transform/names.lua",
		["moonscript.transform"] = "moonscript/transform.lua",
		["moonscript.data"] = "moonscript/data.lua",
		["moonscript.version"] = "moonscript/version.lua",
		["moonscript.types"] = "moonscript/types.lua",
		["moonscript.compile"] = "moonscript/compile.lua",
		["moonscript.parse"] = "moonscript/parse.lua",
		["moonscript.util"] = "moonscript/util.lua",
		["moonscript.dump"] = "moonscript/dump.lua",
		["moonscript.compile.statement"] = "moonscript/compile/statement.lua",
		["moonscript.compile.value"] = "moonscript/compile/value.lua",
		["moonscript"] = "moonscript/init.lua",
		["moonscript.errors"] = "moonscript/errors.lua",
		["moon.all"] = "moon/all.lua",
		["moon"] = "moon/init.lua",
	},
	install = {
		bin = { "bin/moon", "bin/moonc" }
	}
}

