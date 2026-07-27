#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <stdio.h>

#include "moonscript.h"
#include "argparse.h"

// put whatever is on top of stack into package.loaded under name if something
// is not already there
void setloaded(lua_State* l, const char* name) {
	int top = lua_gettop(l);
	lua_getglobal(l, "package");
	lua_getfield(l, -1, "loaded");
	lua_getfield(l, -1, name);
	if (lua_isnil(l, -1)) {
		lua_pop(l, 1);
		lua_pushvalue(l, top);
		lua_setfield(l, -2, name);
	}

	lua_settop(l, top);
}

extern int luaopen_lpeg(lua_State *l);
extern int luaopen_moonscript_parse_native(lua_State *l);

LUALIB_API int luaopen_moonscript(lua_State *l) {
	luaopen_lpeg(l);
	setloaded(l, "lpeg");

	// Load argparse (splat output sets up package.preload)
	if (luaL_loadbuffer(l, (const char *)argparse_lua, argparse_lua_len, "argparse.lua") == 0) {
		lua_call(l, 0, 0);
	}

	// Register the moonscript modules into package.preload
	if (luaL_loadbuffer(l, (const char *)moonscript_lua, moonscript_lua_len, "moonscript.lua") != 0) {
		return 0;
	}
	lua_call(l, 0, 0);

	// The native parser runs its callback chunks at load, and those require
	// moonscript.parse.tree: package.preload must be populated first or the
	// require escapes to the filesystem
	luaopen_moonscript_parse_native(l);
	setloaded(l, "moonscript.parse.native");

	lua_getglobal(l, "require");
	lua_pushstring(l, "moonscript");
	lua_call(l, 1, 1);
	return 1;
}
