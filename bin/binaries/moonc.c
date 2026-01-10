#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <stdio.h>

#include "moonc.h"  // the CLI script

// from moonscript.c
extern int luaopen_moonscript(lua_State *l);

// from lfs.c
extern int luaopen_lfs(lua_State *l);

int main(int argc, char **argv) {
    lua_State *l = luaL_newstate();
    luaL_openlibs(l);

    // Load moonscript (this also loads lpeg and argparse)
    luaopen_moonscript(l);
    lua_pop(l, 1);

    // Load luafilesystem and register it in package.loaded
    int nresults = luaopen_lfs(l);
    if (nresults > 0) {
        lua_getglobal(l, "package");
        lua_getfield(l, -1, "loaded");
        lua_pushvalue(l, -3);  // push lfs table
        lua_setfield(l, -2, "lfs");
        lua_pop(l, 2);  // pop loaded, package
    }
    lua_pop(l, nresults);

    // Set up arg table
    lua_newtable(l);
    lua_pushstring(l, "moonc");
    lua_rawseti(l, -2, -1);
    for (int i = 0; i < argc; i++) {
        lua_pushstring(l, argv[i]);
        lua_rawseti(l, -2, i);
    }
    lua_setglobal(l, "arg");

    // Load and execute the moonc CLI script
    if (luaL_loadbuffer(l, (const char *)moonc_lua, moonc_lua_len, "moonc") != 0) {
        fprintf(stderr, "Failed to load moonc: %s\n", lua_tostring(l, -1));
        return 1;
    }
    if (lua_pcall(l, 0, 0, 0) != 0) {
        fprintf(stderr, "Error: %s\n", lua_tostring(l, -1));
        return 1;
    }

    lua_close(l);
    return 0;
}
