#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <stdio.h>

// from moonscript.c
extern int luaopen_moonscript(lua_State *l);

int main(int argc, char **argv) {
    lua_State *l = luaL_newstate();
    luaL_openlibs(l);

    // Load moonscript (this also loads lpeg)
    luaopen_moonscript(l);
    lua_pop(l, 1); // pop the return value

    // Simple test: require moonscript and compile something
    const char *test_code =
        "local moonscript = require('moonscript')\n"
        "local code = moonscript.to_lua('print \"hello from moonscript\"')\n"
        "print(code)\n"
        "loadstring(code)()\n";

    if (luaL_dostring(l, test_code) != 0) {
        fprintf(stderr, "Test failed: %s\n", lua_tostring(l, -1));
        return 1;
    }

    lua_close(l);
    return 0;
}
