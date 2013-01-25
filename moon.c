
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "moonscript.h"
#include "moon.h"
#include "alt_getopt.h"

#include <stdio.h>

#include "luafilesystem/src/lfs.h"

int main(int argc, char **argv) {
	lua_State *l = luaL_newstate();
	luaL_openlibs(l);

	luaopen_lpeg(l);
	luaopen_lfs(l);

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

