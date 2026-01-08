#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <stdio.h>

#include "moon.h"  // the CLI script

// from moonscript.c
extern int luaopen_moonscript(lua_State *l);

int main(int argc, char **argv) {
    lua_State *l = luaL_newstate();
    luaL_openlibs(l);

    // Load moonscript (this also loads lpeg)
    luaopen_moonscript(l);
    lua_pop(l, 1);

    // Set up arg table
    lua_newtable(l);
    lua_pushstring(l, "moon");
    lua_rawseti(l, -2, -1);
    for (int i = 0; i < argc; i++) {
        lua_pushstring(l, argv[i]);
        lua_rawseti(l, -2, i);
    }
    lua_setglobal(l, "arg");

    // Load and execute the moon CLI script
    if (luaL_loadbuffer(l, (const char *)moon_lua, moon_lua_len, "moon") != 0) {
        fprintf(stderr, "Failed to load moon: %s\n", lua_tostring(l, -1));
        return 1;
    }
    if (lua_pcall(l, 0, 0, 0) != 0) {
        fprintf(stderr, "Error: %s\n", lua_tostring(l, -1));
        return 1;
    }

    lua_close(l);
    return 0;
}
