
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "moonscript.h"
#include "moon.h"
#include "alt_getopt.h"

#include <stdio.h>

#include "luafilesystem/src/lfs.h"

// put whatever is on top of stack into package.loaded under name something is
// already there
void setloaded(lua_State* l, char* name) {
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

int main(int argc, char **argv) {
	lua_State *l = luaL_newstate();
	luaL_openlibs(l);

	luaopen_lpeg(l);
	setloaded(l, "lpeg");
	luaopen_lfs(l);
	setloaded(l, "lfs");

	if (!luaL_loadbuffer(l, (const char *)moonscript_lua, moonscript_lua_len, "moonscript.lua") == 0) {
		fprintf(stderr, "Failed to load moonscript.lua\n");
		return 1;
	}
	lua_call(l, 0, 0);

	if (!luaL_loadbuffer(l, (const char *)alt_getopt_lua, alt_getopt_lua_len, "alt_getopt.lua") == 0) {
		fprintf(stderr, "Failed to load alt_getopt.lua\n");
		return 1;
	}
	lua_call(l, 0, 0);

	int i;
	lua_newtable(l);

	lua_pushstring(l, "moon");
	lua_rawseti(l, -2, -1);

	for (i = 0; i < argc; i++) {
		lua_pushstring(l, argv[i]);
		lua_rawseti(l, -2, i);
	}
	lua_setglobal(l, "arg");

	if (!luaL_loadbuffer(l, (const char *)moon_lua, moon_lua_len, "moon") == 0) {
		fprintf(stderr, "Failed to load moon\n");
		return 1;
	}
	lua_call(l, 0, 0);

	return 0;
}

