{
  target: "reference/api"
  template: "reference"
  title: "Compiler API"
  short_name: "api"
}

# MoonScript Compiler API

## Autocompiling with the `moonscript` Module

After installing MoonScript, you can include the `moonscript` module to make
any Lua script MoonScript aware.

```lua
require "moonscript"
```

After `moonscript` is required, Lua's package loader is updated to search for
`.moon` files on any subsequent calls to `require`. The search path for `.moon`
files is based on the current `package.path` value in Lua when `moonscript` is
required. Any search paths in `package.path` ending in `.lua` are copied,
rewritten to end in `.moon`, and then inserted in `package.moonpath`.

The `moonloader` is the function that is responsible for searching
`package.moonpath` for a file available to be included. It is inserted in the
second position of the `package.loaders` table. This means that a matching `.moon` file
will be loaded over a matching `.lua` file that has the same base name.

For more information on Lua's `package.loaders` see [Lua Reference Manual
&mdash;
package.loaders](http://www.lua.org/manual/5.1/manual.html#pdf-package.loaders)

The `moonloader`, when finding a valid path to a `.moon` file, will parse and
compile the file in memory. The code is then turned into a function using the
built in `load` function, which is run as the module.

If you are executing MoonScript code with the included `moon` command line tool
then it is not required to include this module before including any other
MoonScript modules.

## `moonscript.base` Module

```moononly
moonscript = require "moonscript.base"
```

This module contains an assortment of functions for loading and compiling
MoonScript code from within Lua.

The module provides `load`, `loadfile`, `loadstring` functions, which are
analogous to the similarly named Lua functions. The major difference is that
they load MoonScript code instead of Lua code.


```moononly
moonscript = require "moonscript.base"

fn = moonscript.loadstring 'print "hi!"'
fn!
```

All of these functions can take an optional last argument, a table of options.
The only option right now is `implicitly_return_root`. Setting this to `false`
makes it so the file does not implicitly return its last statement.


```moononly
moonscript = require "moonscript.base"

fn = moonscript.loadstring "10"
print fn! -- prints "10"

fn = moonscript.loadstring "10", implicitly_return_root: false
print fn! -- prints nothing
```

One more useful function is provided: `to_lua`. This function takes a string of
MoonScript code and returns the compiled Lua result along with the line mapping
table. If there are any errors then `nil` and the error message are returned.


```moononly
import to_lua from require "moonscript.base"

lua_code, line_tabel = to_lua [[
x = 124
print "hello world #{x}"
]]
```

Similar to the `load*` functions from above, `to_lua` can take an optional
final argument of a table of options.

The second return value of `to_lua` is useful if you want to perform line
number reversal. It's a table where the key is a Lua line number and the value
is a character offset from the original MoonScript source.

## Programmatically Compiling

If you need finer grained control over the compilation process you can use the
raw parse and compile modules.

Parsing converts a string of MoonScript into an abstract syntax tree. Compiling
converts an abstract syntax tree into a Lua code string.

Knowledge of this API may be useful for creating tools to aid the generation of
Lua code from MoonScript code. For example, you could build a macro system by
analyzing and manipulating the abstract syntax tree. Be warned though, the
format of the abstract syntax tree is undocumented and may change in the
future.

Here is a quick example of how you would compile a MoonScript string to a Lua
String (This is effectively the same as the `to_lua` function described above):

```moononly
parse = require "moonscript.parse"
compile = require "moonscript.compile"

moon_code = [[(-> print "hello world")!]]

tree, err = parse.string moon_code
unless tree
  error "Parse error: " .. err

lua_code, err, pos = compile.tree tree
unless lua_code
  error compile.format_error err, pos, moon_code

-- our code is ready
print lua_code
```
