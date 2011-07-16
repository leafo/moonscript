# MoonScript

MoonScript is a programmer friendly language that compiles into
[Lua](http://ww.lua.org/).  It gives you the power of the fastest scripting
language combined with a rich set of features:

 * Provides a clean syntax using significant whitespace that avoids all the
   keyword noise typically seen in a Lua script.
 
 * Adds table comprehensions, implicit return on functions, classes,
   inheritance, scope management statements `import` & `export`, and a
   convenient object creation statement called `with`.
 
 * Can be loaded directly from a Lua script without an intermediate compile
   step. It even knows how to tell you where errors occurred in the original
   file when they happen.

Creating an instance of a class and calling a method:

     class Thing
       name: "unknown"
     
     class Person extends Thing
       say_name: -> print "Hello, I am", @name
	 
	 with Person!
	   .name = "Moonscript"
	   \say_name!

MoonScript can either be compiled into Lua and run at a later time, or it
can be dynamically compiled and run using the *moonloader*. It's as simple
`require "moon"` in order to have Lua understand how to load and run any
MoonScript file.

The command line tools also let you run MoonScript directly from the
command line, like any first-class scripting language.

## Installation

### Installing with LuaRocks

The easiest way to install is to use Lua rocks and the provide rockspec.

LuaRocks can be obtained [here](http://www.luarocks.org/) or from your package
manager.

After it is installed, run the following in a terminal:

    ~> wget https://raw.github.com/leafo/moonscript/master/moonscript-dev-1.rockspec
    ~> luarocks install moonscript-dev-1.rockspec

This will provide the `moon` and `moonc` tools along with the `moonscript`
Lua module.

### Optional

If you are on Linux and want to run *watch* mode, which compiles `.moon` files to
`.lua` files as they are changed, you can install
[linotify](https://github.com/hoelzro/linotify).


## Learning

Read the [reference manual](docs/index.md).

## Command Line Use

Two tools are installed with MoonScript, `moon` and `moonc`.
`moonc` is used for transforming MoonsScript code into a Lua file.
It takes a list of files, compiles them all, and creates the associated `.lua`
files in the same directories.


### moon

`moon` can be used to run MoonsScript files directly from the command line,
without needing a separate compile step. All MoonsScript files are compiled in
memory as they are run.

Any MoonScript files that are required will also be compiled and run
automatically.

In addition to this, when an error occurs during runtime, the stack trace is
rewritten to give line numbers from the original `.moon` file.

### moonc

`moonc` is used for transforming a MoonsScript file into a Lua file.
It takes a list of files, compiles them all, and creates the associated `.lua`
files alongside the `.moon` files.

You can control where the compiled files are put using the `-t` flag, followed
by a directory.

`moonc` can also take a directory as an argument, and it will recursively scan
for all MoonScript files and compile them.

Combined with `linotify` on linux, the `-w` flag can be used to watch all files
that match the given search path for changes, and then compile them only when
required.


## Overview of Differences & Highlights

A more detailed overview of the syntax can be found in the
[documentation](docs/index.md).

 * Whitespace sensitive blocks defined by indenting
 * All variable declarations are local by default
 * `export` keyword to declare global variables, `import` keyword to make local
   copies of values from a table
 * Parentheses are optional for function calls, similar to Ruby
 * Fat arrow, `=>`, can be used to create a function with a self argument
 * `@` can be prefixed in front of a name to refer to that name in `self`
 * `!` operator can be used to call a function with no arguments
 * Implicit return on functions based on the type of last statement
 * ':' is used to separate key and value in table literals instead of `=`
 * Newlines can be used as table literal entry delimiters in addition to `,`
 * `\` is used to call a method on an object instead of `:`
 * `+=`, `-=`, `/=`, `*=`, `%=` operators
 * `!=` is an alias for `~=`
 * Table comprehensions, with convenient slicing and iterator syntax
 * Lines can be decorated with for loops and if statements at the end of the line
 * If statements can be used as expressions
 * Class system with inheritance based on metatable's `__index` property
 * Constructor arguments can begin with `@` to cause them to automatically be
   assigned to the object
 * Magic `super` function which maps to super class method of same name in a
   class method
 * `with` statement lets you access anonymous object with short syntax


## Dependencies

The following are used in MoonScript:

 * [Lua 5.1](http://lua.org)
 * [LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html)
 * [LuaFileSystem](http://keplerproject.github.com/luafilesystem/)
 * [alt-getopt](http://luaforge.net/projects/alt-getopt/)
 * and optionally on Linux [linotify](https://github.com/hoelzro/linotify)

## License (MIT)

Copyright (C) 2011 by Leaf Corcoran

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.