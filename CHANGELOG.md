

# MoonScript v0.5.0 (2016-9-25)

## Syntax updates

### Function calls

Function calls with parentheses can now have free whitespace around the
arguments. Additionally, a line break may be used in place of a comma:

```moonscript
my_func(
  "first arg"
  =>
    print "some func"

  "third arg", "fourth arg"
)
```

### Function argument definitions

Just like the function all update, function argument definitions have no
whitespace restrictions between arguments, and line breaks can be used to
separate arguments:


```moonscript
some_func = (
  name
  type
  action="print"
) =>
  print name, type, action
```

## Additions

* `elseif` can be used part of an `unless` block (nymphium)
* `unless` conditional expression can contain an assignment like an `if` statement (#251)
* Lua 5.3 bitwise operator support (nymphium) (Kawahara Satoru)
* Makefile is Lua version agnostic (nymphium)
* Lint flag can be used with `moonc` watch mode (ChickenNuggers)
* Lint exits with status 1 if there was a problem detected (ChickenNuggers)
* Compiler can be used with lulpeg

## Bug Fixes

* Slice boundaries can be full expressions (#233)
* Destructure works when used as loop variable in comprehension (#236)
* Proper name local hoisting works for classes again (#287)
* Quoted table key literals can now be parsed when table declaration is in single line (#286)
* Fix an issue where `else` could get attached to wrong `if` statement (#276)
* Loop variables will no longer overwrite variables of the same name in the same scope (egonSchiele)
* A file being deleted will not crash polling watch mode (ChickenNuggers)
* The compiler will not try to compile a directory ending in `.moon` (Gskartwii)
* alt_getopt import works with modern version (Jon Allen)
* Code coverage not being able to find file from chunk name


# MoonScript v0.4.0 (2015-12-06)

## Changes to `super`

`super` now looks up the parent method via the class reference, instead of a
(fixed) closure to the parent class.

Given the following code:

```moonscript
class MyThing extends OtherThing
  the_method: =>
    super!
```

In the past `super` would compile to something like this:

```lua
_parent_0.the_method(self)
```

Where `_parent_0` was an internal local variable that contains a reference to
the parent class. Because the reference to parent is an internal local
variable, you could never swap out the parent unless resorting to the debug
library.

This version will compile to:

```lua
_class_0.__parent.__base.the_method(self)
```

Where `_class_0` is an internal local variable that contains the current class (`MyThing`).

Another difference is that the instance method is looked up on `__base` instead
of the class. The old variation would trigger the metamethod for looking up on
the instance, but a class method of the same name could conflict, take
precedence, and be retuned instead. By referencing `__base` directly we avoid
this issue.

### Super on class methods

`super` can now be used on class methods. It works exactly as you would expect.

```moonscript
class MyThing extends OtherThing
  @static_method: =>
    print super!
```

Calling `super` will compile to:

```moonscript
_class_0.__parent.static_method(self)
```

### Improved scoping for super

The scoping of super is more intelligent. You can warp your methods in other
code and `super` will still generate correctly. For example, syntax like this
will now work as expected:

```moonscript
class Sub extends Base
  value: if debugging
    => super! + 100
  else
    => super! + 10

  other_value: some_decorator {
    the_func: =>
      super!
  }
```

`super` will refer to the lexically closest class declaration to find the name
of the method it should call on the parent.

## Bug Fixes

* Nested `with` blocks used incorrect ref (#214 by @geomaster)
* Lua quote string literals had wrong precedence (#200 by @nonchip)
* Returning from `with` block would generate two `return` statements (#208)
* Including `return` or `break` in a `continue` wrapped block would generate invalid code (#215 #190 #183)

## Other

* Refactor transformer out into multiple files
* `moon` command line script rewritten in MoonScript
* `moonscript.parse.build_grammar` function for getting new instance of parser grammar
* Chain AST updated to be simpler

# MoonScript v0.3.2 (2015-6-01)

## Bug Fixes

* `package.moonpath` geneator does not use paths that don't end in `lua`

# MoonScript v0.3.1 (2015-3-07)

## Bug Fixes

* Fixed a bug where an error from a previous compile would prevent the compiler from running again

# MoonScript v0.3.0 (2015-2-28)

## New Features

* New [unused assignment linter](http://moonscript.org/reference/command_line.html#unused_variable_assigns) finds assignments that are never referenced after being defined.

## Parsing Updates

Whitespace parsing has been relaxed in a handful of locations:

* You can put unrestricted whitespace/newlines after operator in a binary operator before writing the right hand side. The following are now valid:

```moonscript
x = really_long_function! +
  2304

big_math = 123 /
  12 -
  43 * 17


bool_exp = nice_shirt and cool_shoes or
  skateboard and shades
```

* You can put unrestricted whitespace/newlines immediately after an opening parenthesis, and immediately before closing parenthesis. The following are now valid:

```moonscript
hello = 100 + (
  var * 0.23
) - 15


funcall(
  "height", "age", "weight"
)


takes_two_functions (->
  print "hello"
), ->
  print "world"
```

* You can put unrestricted whitespace/newlines immediately after a `:` when defining a table literal. The following is now valid:

```moonscript
x = {
  hello:
    call_a_function "football", "hut"
}
```

## Code Generation

* Single value `import`/`destructure` compiles directly into single assignment

## Bug Fixes

* Some `moonc` command line flags were being ignored
* Linter would not report global reference when inside self assign in table
* Fixed an issue where parser would crash in Lpeg 0.12 when compiling hundreds of times per process

## Misc

* MoonScript parser now written in MoonScript

# MoonScript v0.2.6 (2014-6-18)

## Bug Fixes

* Fixes to posmap generation for multi-line mappings and variable declarations
* Prefix file name with `@` when loading code so stack traces tread it as file
* Fix bug where `moonc` couldn't work with absolute paths
* Improve target file path generation for `moonc`

# MoonScript v0.2.5 (2014-3-5)

## New Things

* New [code coverage tool](http://moonscript.org/reference/#code_coverage) built into `moonc`
* New [linting tool](http://moonscript.org/reference/#linter) built into `moonc`, identifies global variable references that don't pass whitelist
* Numbers can have `LL` and `ULL` suffixes for LuaJIT

## Bug Fixes

* Error messages from `moonc` are written to standard error
* Moonloader correctly throws error when moon file can't be parsed, instead of skipping the module
* Line number rewriting is no longer incorrectly offset due to multiline strings

## Code Generation

Bound functions will avoid creating an anonymous function unless necessary.

```moonscript
x = hello\world
```

**Before:**

```lua
local x = (function()
  local _base_0 = hello
  local _fn_0 = _base_0.world
  return function(...)
    return _fn_0(_base_0, ...)
  end
end)()
```

**After:**

```lua
local x
do
  local _base_0 = hello
  local _fn_0 = _base_0.world
  x = function(...)
    return _fn_0(_base_0, ...)
  end
end
```

Explicit return statement now avoids creating anonymous function for statements
where return can be cascaded into the body.

```moon
->
  if test1
    return [x for x in *y]

  if test2
    return if true
      "yes"
    else
      "no"

  false
```


**Before:**

```lua
local _
_ = function()
  if test1 then
    return (function()
      local _accum_0 = { }
      local _len_0 = 1
      local _list_0 = y
      for _index_0 = 1, #_list_0 do
        local x = _list_0[_index_0]
        _accum_0[_len_0] = x
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)()
  end
  if test2 then
    return (function()
      if true then
        return "yes"
      else
        return "no"
      end
    end)()
  end
  return false
end
```

**After:**

```lua
local _
_ = function()
  if test1 then
    local _accum_0 = { }
    local _len_0 = 1
    local _list_0 = y
    for _index_0 = 1, #_list_0 do
      local x = _list_0[_index_0]
      _accum_0[_len_0] = x
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end
  if test2 then
    if true then
      return "yes"
    else
      return "no"
    end
  end
  return false
end
```



# MoonScript v0.2.4 (2013-07-02)

## Changes

* The way the subtraction operator works has changed. There was always a little confusion as to the rules regarding whitespace around it and it was recommended to always add whitespace around the operator when doing subtraction. Not anymore. Hopefully it now [works how you would expect](http://moonscript.org/reference/#considerations). (`a-b` compiles to `a - b` and not `a(-b)` anymore).
* The `moon` library is no longer sets a global variable and instead returns the module. Your code should now be:

```moonscript
moon = require "moon"
```

* Generated code will reuse local variables when appropriate. Local variables are guaranteed to not have side effects when being accessed as opposed to expressions and global variables. MoonScript will now take advantage of this and reuse those variable without creating and copying to a temporary name.
* Reduced the creation of anonymous functions that are called immediately.
  MoonScript uses this technique to convert a series of statements into a single expression. It's inefficient because it allocates a new function object and has to do a function call. It also obfuscates stack traces.  MoonScript will flatten these functions into the current scope in a lot of situations now.
* Reduced the amount of code generated for classes. Parent class code it left out if there is no parent.

## New Things

* You can now put line breaks inside of string literals. It will be replaced with `\n` in the generated code.

```moonscript
x = "hello
world"
```

* Added `moonscript.base` module. It's a way of including the `moonscript` module without automatically installing the moonloader.
* You are free to use any whitespace around the name list in an import statement. It has the same rules as an array table, meaning you can delimit names with line breaks.

```moonscript
import a, b
  c, d from z
```

* Added significantly better tests. Previously the testing suite would only verify that code compiled to an expected string. Now there are unit tests that execute the code as well. This will make it easier to change the generated output while still guaranteeing the semantics are the same.

## Bug Fixes

* `b` is not longer treated as self assign in `{ a : b }`
* load functions will return `nil` instead of throwing error, as described in documentation
* fixed an issue with `moon.mixin` where it did not work as described


# MoonScript v0.2.3-2 (2013-01-29)

Fixed bug with moonloader not loading anything

# MoonScript v0.2.3 (2013-01-24)

## Changes

* For loops when used as expressions will no longer discard nil values when accumulating into an array table. **This is a backwards incompatible change**. Instead you should use the `continue` keyword to filter out iterations you don't want to keep. [Read more here](https://github.com/leafo/moonscript/issues/66).
* The `moonscript` module no longer sets a global value for `moonscript` and instead returns it. You should update your code:

```moonscript
moonscript = require "moonscript"
```

## New Things

* Lua 5.2 Support. The compiler can now run in either Lua 5.2 and 5.1
* A switch `when` clause [can take multiple values](http://moonscript.org/reference/#switch), comma separated.
* Added [destructuring assignment](http://moonscript.org/reference/#destructuring_assignment).
* Added `local *` (and `local ^`) for [hoisting variable declarations](http://moonscript.org/reference/#local_statement) in the current scope
* List comprehensions and line decorators now support numeric loop syntax

## Bug Fixes

* Numbers that start with a dot, like `.03`, are correctly parsed
* Fixed typo in `fold` library function
* Fix declaration hoisting inside of class body, works the same as `local *` now

## Other Stuff

MoonScript has [made its way into GitHub](https://github.com/github/linguist/pull/246). `.moon` files should start to be recognized in the near future.


# MoonScript v0.2.2 (2012-11-03)

## Changes

* Compiled [files will now implicitly return](http://moonscript.org/reference/#implicit_returns_on_files) their last statement. Be careful, this might change what `require` returns.

## New Things

### The Language

* Added [`continue` keyword](http://moonscript.org/reference/#continue) for skipping the current iteration in a loop.
* Added [string interpolation](http://moonscript.org/reference/#string_interpolation).
* Added [`do` expression and block](http://moonscript.org/reference/#do).
* Added `unless` as a block and line decorator. Is the inverse of `if`.
* Assignment can be used in an [`if` statement's expression](http://moonscript.org/reference/#with_assignment).
* Added `or=` and `and=` operators.
* `@@` can be prefixed in front of a name to access that name within `self.__class`
* `@` and `@@` can be [used as values](http://moonscript.org/reference/#_and__values) to reference `self` and `self.__class`.
* In class declarations it's possible to [assign to the class object](http://moonscript.org/reference/#class_variables) instead of the instance metatable by prefixing the key with `@`.
* Class methods can access [locals defined within the body](http://moonscript.org/reference/#class_declaration_statements) of the class declaration.
* Super classes are [notified when they are extended](http://moonscript.org/reference/#inheritance) from with an `__inherited` callback.
* Classes can now [implicitly return and be expressions](http://moonscript.org/reference/#anonymous_classes).
* `local` keyword returns, can be used for forward declaration or shadowing a variable.
* String literals can be used as keys in [table literals](http://moonscript.org/reference/#table_literals).
* Call methods on string literals without wrapping in parentheses: `"hello"\upper!`
* Table comprehensions can return a single value that is unpacked into the key and value.
* The expression in a [`with` statement can now be an assignment](http://moonscript.org/reference/#with_statement), to give a name to the expression that is being operated on.


### The API

* The `load` functions can take an [optional last argument of options](http://moonscript.org/reference/#load_functions).

### The Tools

* The [online compiler](http://moonscript.org/compiler/) now runs through a web service instead of emscripten, should work reliably on any computer now.
* [Windows binaries](http://moonscript.org/bin/) have been updated.

## Bug Fixes

* Significantly improved the [line number rewriter](http://moonscript.org/reference/#error_rewriting). It should now accurately report all line numbers.
* Generic `for` loops correctly parse for multiple values as defined in Lua.
* Update expressions don't fail with certain combinations of precedence.
* All statements/expressions are allowed in a class body, not just some.
* `x = "hello" if something` will extract the declaration of `x` if it's not in scope yet. Preventing an impossible to access variable from being created.
* varargs, `...`, correctly bubble up through automatically generated anonymous functions.
* Compiler doesn't crash if you try to assign something that isn't assignable.
* Numerous other small fixes. See [commit log](https://github.com/leafo/moonscript/commits/master).


# MoonScript v0.2.0 (2011-12-12)

## Changes

* `,` is used instead of `:` for delimiting table slice parts.
* Class objects store the metatable of their instances in `__base`. `__base` is also used in inheritance when chaining metatables.

## New Things

### The Language

* Added [key-value table comprehensions][4].
* Added a [`switch` statement][7].
* The body of a class can contain arbitrary expressions in addition to assigning properties. `self` in this scope refers to the class itself.
* Class objects themselves support accessing the properties of the superclass they extend (like instances).
* Class objects store their name as a string in the `__name` property.
* [Enhanced the `super` keyword][8] in instance methods.
* Bound methods can be created for an object by using `object\function_name` as a value. Called [function stubs][6].
* Added `export *` statement to export all assigned names following the statement.
* Added `export ^` statement to export all assigning names that begin with a capital letter following the statement.
* `export` can be used before any assignment or class declaration to export just that assignment (or class declaration).
* Argument lists can be broken up over several lines with trailing comma.
* `:hello` is short hand for `hello: hello` inside of table literal.
* Added `..=` for string concatenation.
* `table.insert` no longer used to build accumlated values in comprehensions.

### The API

* Added `loadfile`, `loadstring`, and `dofile` functions to `moonscript` module to load/run MoonScript code.
* Added `to_lua` function to `moonscript` module to convert a MoonScript code string to Lua string.

### The Tools

* Created [prebuilt MoonScript Windows executables][2].
* Wrote a [Textmate/Sublime Text bundle][9].
* Wrote a [SciTE syntax highlighter with scintillua][10].
* Created a [SciTE package for Windows][11] that has everything configured.
* Created an [online compiler and snippet site][12] using [emscripten][13].
* Watch mode works on all platforms now. Uses polling if `inotify` is not
  available.

### Standard Library

I'm now including a small set of useful functions in a single module called `moon`:

```moonscript
require "moon"
```

Documentation is [available here][3].

## Bug Fixes

* Windows line endings don't break the parser.
* Fixed issues when using `...` within comprehensions when the compiled code uses an intermediate function in the output.
* Names whose first characters happen to be a keyword don't break parser.
* Return statement can have no arguments
* argument names prefixed with `@` in function definitions work outside of classes work with default values.
* Fixed parse issues with the shorthand values within a `with` block.
* Numerous other small fixes. See [commit log][5].

## Other Stuff

Since the first release, I've written one other project in MoonScript (other than the compiler). It's a static site generator called [sitegen][15]. It's what I now use to generate all of my project pages and this blog.

# MoonScript 0.1.0 (2011-08-12)

Initial release


  [1]: http://moonscript.org
  [2]: http://moonscript.org/bin/
  [3]: http://moonscript.org/reference/standard_lib.html
  [4]: http://moonscript.org/reference/#table_comprehensions
  [5]: https://github.com/leafo/moonscript/commits/master
  [6]: http://moonscript.org/reference/#function_stubs
  [7]: http://moonscript.org/reference/#switch
  [8]: http://moonscript.org/reference/#super
  [9]: https://github.com/leafo/moonscript-tmbundle
  [10]: https://github.com/leafo/moonscript/tree/master/extra/scintillua
  [11]: http://moonscript.org/scite/
  [12]: http://moonscript.org/compiler/
  [13]: http://emscripten.org
  [14]: http://twitter.com/moonscript
  [15]: http://leafo.net/sitegen/

