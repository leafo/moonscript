    target: reference/standard_lib
    template: reference
    title: MoonScript v0.2.0 - Standard Library
--

The MoonScript installation comes with a small kernel of functions that can be
used to perform various common things.

The entire library is currently contained in a single object. We can bring this
`moon` object into scope by requiring `"moon"`.

    require "moon"
    -- `moon.p` is the debug printer
    moon.p { hello: "world" }

If you prefer to just inject all of the functions into the current scope, you
can require `"moon.all"` instead. The following has the same effect as above:

    require "moon.all"
    p { hello: "world" }

All of the functions are compatible with Lua in addition to MoonScript, but
some of them only make sense in the context of MoonScript.


# MoonScript Standard Library

This is an overview of all the included functions.
All of the examples assume that the standard library has been included with
`require "moon.all"`.

## Printing Functions

### `p(arg)`

Prints a formatted version of an object. Excellent for introspecting the contents
of a table.


## Table Functions

### `run_with_scope(fn, scope, [args...])`

Mutates the environment of function `fn` and runs the function with any extra
args in `args...`. Returns the result of the function.

The environment of the function is set to a new table whose metatable will use
`scope` to look up values. `scope` must be a table. If `scope` does not have an
entry for a value, it will fall back on the original environment.

    my_env = {
      secret_function: -> print "shhh this is secret"
      say_hi: -> print "hi there!"
    }

    say_hi = -> print "I am a closure"

    fn = ->
      secret_function!
      say_hi!

    run_with_scope fn, my_env


Note that any closure values will always take precedence against global name
lookups in the environment. In the example above, the `say_hi` in the
environment has been shadowed by the local variable `say_hi`.

### `defaultbl([tbl,] fn)`

Sets the `__index` of table `tbl` to use the function `fn` to generate table
values when a missing key is looked up.

### `extend`
### `copy`

## Class/Object Functions

### `bind_methods`
### `mixin`
### `mixin_object`
### `mixin_table`

## Misc Functions

### `fold`

## Debug Functions

### `debug.upvalue`
