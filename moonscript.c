
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "moonscript.h"

#include <stdio.h>

extern int luaopen_lpeg(lua_State *l);

LUALIB_API int luaopen_moonscript(lua_State *l) {
	luaopen_lpeg(l);
	if (luaL_loadbuffer(l, (const char *)moonscript_lua, moonscript_lua_len, "moonscript.lua") == 0) {
		lua_call(l, 0, 1);
		return 1;
	}
	return 0;
};

