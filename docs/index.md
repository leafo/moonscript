# MoonScript

MoonScript compiles to Lua

## Function Literals

## Table Literals

## Table Comprehensions

## Conditionals

## Import Statement

Often you want to bring some values from a table into the current scope as
local variables by their name. The import statement lets us accomplish this:

    import insert from table

The multiple names can be given, each separated by a comma:

    import C, Ct, Cmt from lpeg

Sometimes a function requires that the table be sent in as the first argument
(when using the `:` syntax). As a shortcut, we can prefix the name with a `:`
to bind it to that table:

    -- some object
    my_module = 
        state: 100 
        add: (value) =>
            self.state + value

    import :add from my_module

    print add(22) -- equivalent to calling my_module:get(22)

## The Using Clause; Controlling Destructive Assignment

While lexical scoping can be a great help in reducing the complexity of the
code we write, things can get unwieldy as the code size increases. Consider
the following snippet:

    i = 100

    -- many lines of code...

    my_func = ->
        i = 10
        while i > 0
            print i
            i -= 1

    my_func()

    print i -- will print 0


In `my_func`, we've overwritten the value of `i` mistakenly. In this example it
is quite obvious, but consider a large, or foreign code base where it isn't
clear what names have already been declared.

It would be helpful to say which variables from the enclosing scope we intend
on change, in order to prevent us from changing others by accident.

The `using` keyword lets us do that. `using nil` makes sure that no closed
variables are overwritten in assignment. The `using` clause is placed after the
argument list in a function, or in place of it if there are no arguments.

    i = 100

    my_func = (using nil) ->
        i = "hello" -- a new local variable is created here

    my_func()
    print i -- prints 100, i is unaffected


Multiple names can be separated by commas. Closure values can still be
accessed, they just cant be modified:

    tmp = 1213
    i, k = 100, 50

    my_func = (add using k,i) ->
        tmp = tmp + add -- a new local tmp is created 
        i += tmp
        k += tmp

    my_func(22)
    print i,k -- these have been updated

