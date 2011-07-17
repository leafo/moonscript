# MoonScript

MoonScript compiles to Lua

## Assignment

Unlike Lua, there is no local keyword. All assignments to names that are not
already defined will be declared as local to the scope of that declaration. If
you wish to create a global variable it must be done using the `export`
keyword.

    hello = "world"
    a,b,c = 1, 2, 3


## Update Assignment

`+=`, `-=`, `/=`, `*=`, `%=` operators have been added for updating a value by
a certain amount have been added. They are aliases for their expanded
equivalents.

    x += 10

Is the same as:

    x = x + 10

## Comments 

Like Lua, comments start with `--` and continue to the end of the line.

## Literals & Operators

MoonScript supports all the same primitive literals as Lua and uses the same
syntax. This applies to numbers, strings, booleans, and `nil`.

MoonScript also supports all the same binary and unary operators. `!=` is also
added as an alias of `~=`.

## Function Literals

All functions are created using a function expression. A simple function is
denoted using the arrow: `->`

    my_function = ->
    my_function() -- does nothing


The body of the function can either by one statement placed directly after the
arrow, or it can be a series of statements indented on the following line:

    func_a = -> print "hello world"

    func_b = ->
      value = 100
      print "The value:", value

If a function has no arguments, it can be called using the `!` operator,
instead of empty parentheses.

We can call the two functions above like so:

    func_a! -- equivalent to `func_a()`
    func_b!

Functions with arguments can be created by preceding the arrow with a list of
argument names in parentheses:

    sum = (x, y) -> print "sum", x + y

Functions can be called by listing the values of the arguments after the name
of the variable where the function is stored:

    sum 10, 20

Functions will coerce the last statement in their body into a return statement,
giving you implicit return:

    sum = (x, y) -> x + y
    print "The sum is ", sum 10, 20

Of course if you wanted to explicitly return, you can use the `return` keyword.

    sum = (x, y) -> return x + y

In order to avoid ambiguity in when calling functions, parentheses can be used
to surround the arguments. This is required here in order to make sure the
right arguments get sent to the right functions.

    print "sum 1:", sum(10, 20), "sum 1:", sum(30, 40)


The following are equivalent:

    print "the value is", sum 10, get_number "decimal", "1 thousand"

    print("the value is", sum(10, get_number("decimal", "1 thousand")))

### Fat Arrows

Because it is an idiom in Lua to send the object as the first argument when
calling a method, a special syntax is provided for functions which
automatically includes this `self` argument.

    func = (num) => self.value + num

Is the same as:

    func = (self, num) -> self.value + num

## Table Literals

Like in Lua, tables are delimited in curly braces.

    some_values = { 1, 2, 3, 4 }

Unlike Lua, assigning a value to a key in a table is done with `:` (instead of
`=`).

    some_values = {
      name: "Bill",
      age: 200,
      ["favorite food"]: "rice"
    }

The curly braces can be left off if a single table is being assigned.

    profile = 
      height: "4 feet",
      shoe_size: 13,
      favorite_foods: {"ice cream", "donuts"}

Newlines can be used to delimit values instead of a comma (or both):

    values = {
      1,2,3,4
      5,6,7,8
      name: "superman"
      occupation: "crime fighting"
    }

## Table Comprehensions

Table comprehensions provide a quick way to iterate over a table's values while
applying a statement and accumulating the result.

The following creates a copy of the `items` table but with all the values
doubled.

    items = { 1, 2, 3, 4  5}
    doubled = [item * 2 for i, item in ipairs items]

The items included in the new table can be restricted with a `when` clause:

    slice = [item in i, item in ipairs items when i > 1 and i < 3]

Because it is common to iterate over the values of a numerically indexed table,
an `*` operator is introduced. The doubled example can be rewritten as:

    doubled = [item for item in *items]

The `for` and `when` clauses can be chained as much as desired. The only
requirement on a comprehension is that there is at least one `for` clause.

Using multiple `for` clauses is the same as using nested loops:

    x_coords = {4, 5, 6, 7}
    y_coords = {9, 2, 3}

    pairs = [{x,y} for x in *x_coords for y in *y_coords]


## For Loop

There are two for loop forms, just line in Lua. A numeric one and a generic one:

    for i = 10, 20
      print i

    for k = 1,15,2 -- an optional step provided
      print k 

    for key, value in pairs object
        print key, value
    
The slicing and `*` operators can be used, just like with table comprehensions:

    for item in *items[2:4]
      print item

A shorter syntax is also available for all variations when the body is only a
single line:

    for item in *items do print item

    for j = 1,10,3 do print j

A for loop can also be used an expression. The last statement in the body of
the for loop is coerced into an expression and appended to an accumulating
table if the value of that expression is not nil.

Doubling every even number:

    doubled_evens = for i=1,20
      if i % 2 == 0
        i * 2
      else
        i

Filtering out odd numbers:
    
    my_numbers = {1,2,3,4,5,6}
    odds = for x in *my_numbers
      if x % 2 == 1 then x

For loops at the end of a function body are not accumulated into a table for a
return value (Instead the function will return `nil`).  Either an explicit
`return` statement can be used, or the loop can be converted into a list
comprehension.

    func_a -> for i=1,10 do i
    func_b -> return for i=1,10 do i

    print func_a! -- prints nil
    print func_b! -- prints table object

This is done to avoid the needless creation of tables for functions that don't
need to return the results of the loop.

## While Loop

The while loop also comes in two variations:

    i = 10
    while i > 0
      print i
      i -= 1

    while running == true do my_function!

Like for loops, the while loop can also be used an expression. Additionally,
for a function to return the accumlated value of a while loop, the statement
must be explicitly returned.

## Conditionals

    have_coins = false
    if have_coins
      print "I have coins"
	else
      print "I don't have coins"

A short syntax for single statements can also be used:

	have_coins = false
    if have_coins then print "I have coins" else print "I don't have coins"


Because if statements can be used as expressions, this can able be written as:

	have_coins = false
	print if have_coins then "I have coins" else "I don't have coints"

Conditionals can also be used in return statements and assignments:

    is_tall = (name) ->
      if name == "Rob"
        true
      else
        false

    message = if is_tall "Rob"
      "I am very tall"
    else
      "I am not so tall"

    print message -- prints: I am very tall


## Line Decorators

For convenience, the for loop and if statement can be applied to single
statements at the end of the line:

    print "hello world" if name == "Rob"

This is equivalent to:

    if name == "rob"
      print "hello world"

And with basic loops:

    print "item: ", item for item in *items

## Object Oriented Programming

A simple class:

    class Inventory
      new: =>
        @items = {}

      add_item: (name) =>
        if @items[name]
          @items[name] += 1
        else
          @items[name] = 1

A class is declared with a `class` statement followed by a table-like
declaration where all of the methods and properties are listed.

The `new` property is special in that it will become the constructor.

Notice how all the methods in the class use the fat arrow function syntax. When
calling methods on a instance, the instance itself is sent in as the first
argument. The fat arrow handles the creation of a `self` variable.

The `@` prefix on a variable name is shorthand for `self.`. `@items` becomes
`self.items`.

Creating an instance of the class is done by calling the name of the class as a
function.

    inv = Inventory!
    inv\add_item "t-shirt"
    inv\add_item "pants"

Because the instance of the class needs to be sent to the methods when they are
called, the '\' operator is used.

All properties of a class are shared among the instances. This is fine for
functions, but for other types of objects, undesired results may occur:

    class Person
      clothes: {}
      give_item: (name) =>
        table.insert @clothes, name

    a = Person!
    b = Person!

    a\give_item "pants"
    b\give_item "shirt"

    print item for item in *a.clothes -- will print both pants and shirt

### Inheritance

The `extends` keyword can be used in a class declaration to inherit the
properties and methods from another class.

    class BackPack extends Inventory
      size: 10
      add_item: (name) =>
        if #@items > size then error "backpack is full"
        super name

Here we extend our Inventory class, and limit the amount of items it can carry.
The `super` keyword can be called as a function to call the function of the
same name in the super class. It can also be accessed like an object in order
to retrieve values in the parent class that might have been shadowed by the
child class.

### Types

Every instance of a class carries its type with it. This is stored in the
special `__class` property. This property holds the class object. The class
object is what we call to build a new instance. We can also index the class
object to retrieve class methods and properties.

    
    b = BackPack!
    assert b.__class == BackPack

    print BackPack.size -- prints 10


## Export Statement

Because, by default, all assignments to variables that are not lexically visible will
be declared as local, special syntax is required to declare a variable globally.

The export keyword makes it so any following assignments to the specified names
will not be assigned locally.

	export var-name [, var-name2, ...]

This is especially useful when declaring what will be externally visible in a
module:

	-- my_module.moon
	module "my_module", package.seeall
    export print_result

	length = (x, y) -> math.sqrt x*x + y*y

	print_result = (x, y) ->
	  print "Length is ", length x, y

	-- main.moon
	require "my_module"

	my_module.print_result 4, 5 -- prints the result

	print my_module.length 6, 7 -- errors, `length` not visible


## Import Statement

Often you want to bring some values from a table into the current scope as
local variables by their name. The import statement lets us accomplish this:

    import insert from table

The multiple names can be given, each separated by a comma:

    import C, Ct, Cmt from lpeg

Sometimes a function requires that the table be sent in as the first argument
(when using the `\` syntax). As a shortcut, we can prefix the name with a `\`
to bind it to that table:

    -- some object
    my_module = 
        state: 100 
        add: (value) =>
            self.state + value

    import \add from my_module

    print add(22) -- equivalent to calling my_module:get(22)

## With Statement

A common pattern involving the creation of an object is calling a series of
functions and setting a series of properties immediately after creating it.

This results in repeating the name of the object multiple times in code, adding
unnecessary noise. A common solution to this is to pass a table in as an
argument which contains a collection of keys and values to overwrite. The
downside to this is that the constructor of this object must support this form.

The `with` block helps to alleviate this. It lets us use a bare function and
index syntax in order to work with the object:

    with Person!
      .name = "Oswald"
      \add_relative my_dad
      \save!
      print .name

Is equivalent to:

    _person = Person!
    _person.name = "Oswald"
    _person\add_relative my_dad
    _person\save!
    print _person.name

This is more expressive than trying to create multiple constructors to handle
unique instances of initializing an object.

The `with` statement can also be used as an expression which returns the newly
created object.

    file = with File "favorite_foods.txt"
      \set_encoding "utf8"

Or...

    create_person = (name,  relatives) ->
      with Person!
        .name = name
        \add_relative for relative in *relatives

    me = create_person "Leaf", {dad, mother, sister}

## The Using Clause; Controlling Destructive Assignment

*This isn't implemented yet*

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

