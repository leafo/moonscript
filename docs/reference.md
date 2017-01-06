{
  target: "reference/index"
  template: "reference"
  title: "Language Guide"
  short_name: "lang"
}

MoonScript is a programming language that compiles to
[Lua](http://www.lua.org). This guide expects the reader to have basic
familiarity with Lua. For each code snippet below, the MoonScript is on the
left and the compiled Lua is on right right.

This is the official language reference manual, installation directions and the
homepage are located at <http://moonscript.org>.

<div class="github-buttons">
<iframe src="http://ghbtns.com/github-btn.html?user=leafo&repo=moonscript&type=watch&count=true" allowtransparency="true" frameborder="0" scrolling="0" width="110px" height="20px"></iframe>
<iframe src="http://ghbtns.com/github-btn.html?user=leafo&repo=moonscript&type=fork&count=true" allowtransparency="true" frameborder="0" scrolling="0" width="95px" height="20px"></iframe>
</div>

# The Language

## Whitespace

MoonScript is a whitespace sensitive language. This means that
instead of using `do` and `end` (or `{` and `}`) to delimit sections of code we
use line-breaks and indentation.

This means that how you indent your code is important. Luckily MoonScript
doesn't care how you do it but only requires that you be consistent.

An indent must be at least 1 space or 1 tab, but you can use as many as you
like. All the code snippets on this page will use two spaces.

> Should you happen to mix tabs and spaces, a tab is equivalent to 4 spaces. I
> shouldn't be telling you this though because you should never do it.

## Assignment

Assigning to an undeclared name will cause it to be declared as a new local
variable. The language is dynamically typed so you can assign any value to any
variable. You can assign multiple names and values at once just like Lua:

```moon
hello = "world"
a,b,c = 1, 2, 3
hello = 123 -- uses the existing variable
```

If you wish to create a global variable it must be done using the
[`export`](#export_statement) keyword.

The [`local`](#local_statement) keyword can be used to forward declare a
variable, or shadow an existing one.

## Update Assignment

`+=`, `-=`, `/=`, `*=`, `%=`, `..=`, `or=`, `and=`, `&=`, `|=`, `>>=`, and
`<<=` operators have been added for updating and assigning at the same time.
They are aliases for their expanded equivalents.

```moon
x = 0
x += 10

s = "hello "
s ..= "world"

b = false
b and= true or false

p = 50
p &= 5
p |= 3
p >>= 3
p <<= 3
```

## Comments

Like Lua, comments start with `--` and continue to the end of the line.
Comments are not written to the output.

```moon
-- I am a comment
```

## Literals & Operators

All of the primitive literals in Lua can be used. This applies to numbers,
strings, booleans, and `nil`.

All of Lua's binary and unary operators are available. Additionally `!=` is as
an alias for `~=`.

Unlike Lua, Line breaks are allowed inside of single and double quote strings
without an escape sequence:

```moon
some_string = "Here is a string
  that has a line break in it."
```

## Function Literals

All functions are created using a function expression. A simple function is
denoted using the arrow: `->`

```moon
my_function = ->
my_function() -- call the empty function
```

The body of the function can either be one statement placed directly after the
arrow, or it can be a series of statements indented on the following lines:

```moon
func_a = -> print "hello world"

func_b = ->
  value = 100
  print "The value:", value
```

If a function has no arguments, it can be called using the `!` operator,
instead of empty parentheses. The `!` invocation is the preferred way to call
functions with no arguments.

```moon
func_a!
func_b()
```

Functions with arguments can be created by preceding the arrow with a list of
argument names in parentheses:

```moon
sum = (x, y) -> print "sum", x + y
```

Functions can be called by listing the arguments after the name of an expression
that evaluates to a function. When chaining together function calls, the
arguments are applied to the closest function to the left.

```moon
sum 10, 20
print sum 10, 20

a b c "a", "b", "c"
```

In order to avoid ambiguity in when calling functions, parentheses can also be
used to surround the arguments. This is required here in order to make sure the
right arguments get sent to the right functions.

```moon
print "x:", sum(10, 20), "y:", sum(30, 40)
```

There must not be any space between the opening parenthesis and the function.

Functions will coerce the last statement in their body into a return statement,
this is called implicit return:

```moon
sum = (x, y) -> x + y
print "The sum is ", sum 10, 20
```

And if you need to explicitly return, you can use the `return` keyword:

```moon
sum = (x, y) -> return x + y
```

Just like in Lua, functions can return multiple values. The last statement must
be a list of values separated by commas:

```moon
mystery = (x, y) -> x + y, x - y
a,b = mystery 10, 20
```

### Fat Arrows

Because it is an idiom in Lua to send an object as the first argument when
calling a method, a special syntax is provided for creating functions which
automatically includes a `self` argument.

```moon
func = (num) => @value + num
```

### Argument Defaults

It is possible to provide default values for the arguments of a function. An
argument is determined to be empty if its value is `nil`. Any `nil` arguments
that have a default value will be replace before the body of the function is run.

```moon
my_function = (name="something", height=100) ->
  print "Hello I am", name
  print "My height is", height
```

An argument default value expression is evaluated in the body of the function
in the order of the argument declarations. For this reason default values have
access to previously declared arguments.

```moon
some_args = (x=100, y=x+1000) ->
  print x + y
```

### Considerations

Because of the expressive parentheses-less way of calling functions, some
restrictions must be put in place to avoid parsing ambiguity involving
whitespace.

The minus sign plays two roles, a unary negation operator and a binary
subtraction operator. Consider how the following examples compile:

```moon
a = x - 10
b = x-10
c = x -y
d = x- z
```

The precedence of the first argument of a function call can be controlled using
whitespace if the argument is a literal string. In Lua, it is common to leave
off parentheses when calling a function with a single string or table literal.

When there is no space between a variable and a string literal, the
function call takes precedence over any following expressions. No other
arguments can be passed to the function when it is called this way.

Where there is a space following a variable and a string literal, the function
call acts as show above. The string literal belongs to any following
expressions (if they exist), which serves as the argument list.

```moon
x = func"hello" + 100
y = func "hello" + 100
```

### Multi-line arguments

When calling functions that take a large number of arguments, it is convenient
to split the argument list over multiple lines. Because of the white-space
sensitive nature of the language, care must be taken when splitting up the
argument list.

If an argument list is to be continued onto the next line, the current line
must end in a comma. And the following line must be indented more than the
current indentation. Once indented, all other argument lines must be at the
same level of indentation to be part of the argument list

```moon
my_func 5,4,3,
  8,9,10

cool_func 1,2,
  3,4,
  5,6,
  7,8
```

This type of invocation can be nested. The level of indentation is used to
determine to which function the arguments belong to.

```moon
my_func 5,6,7,
  6, another_func 6,7,8,
    9,1,2,
  5,4
```

Because [tables](#table_literals) also use the comma as a delimiter, this
indentation syntax is helpful for letting values be part of the argument list
instead of being part of the table.

```moon
x = {
  1,2,3,4, a_func 4,5,
    5,6,
  8,9,10
}
```

Although uncommon, notice how we can give a deeper indentation for function
arguments if we know we will be using a lower indentation further on.

```moon
y = { my_func 1,2,3,
   4,5,
  5,6,7
}
```

The same thing can be done with other block level statements like
[conditionals](#conditionals). We can use indentation level to determine what
statement a value belongs to:

```moon
if func 1,2,3,
  "hello",
  "world"
    print "hello"
    print "I am inside if"

if func 1,2,3,
    "hello",
    "world"
  print "hello"
  print "I am inside if"
```

## Table Literals

Like in Lua, tables are delimited in curly braces.

```moon
some_values = { 1, 2, 3, 4 }
```

Unlike Lua, assigning a value to a key in a table is done with `:` (instead of
`=`).

```moon
some_values = {
  name: "Bill",
  age: 200,
  ["favorite food"]: "rice"
}
```

The curly braces can be left off if a single table of key value pairs is being
assigned.

```moon
profile =
  height: "4 feet",
  shoe_size: 13,
  favorite_foods: {"ice cream", "donuts"}
```

Newlines can be used to delimit values instead of a comma (or both):

```moon
values = {
  1,2,3,4
  5,6,7,8
  name: "superman"
  occupation: "crime fighting"
}
```

When creating a single line table literal, the curly braces can also be left
off:

```moon
my_function dance: "Tango", partner: "none"

y = type: "dog", legs: 4, tails: 1
```

The keys of a table literal can be language keywords without being escaped:

```moon
tbl = {
  do: "something"
  end: "hunger"
}
```

If you are constructing a table out of variables and wish the keys to be the
same as the variable names, then the `:` prefix operator can be used:

```moon
hair = "golden"
height = 200
person = { :hair, :height, shoe_size: 40 }

print_table :hair, :height
```

If you want the key of a field in the table to to be result of an expression,
then you can wrap it in `[` `]`, just like in Lua. You can also use a string
literal directly as a key, leaving out the square brackets. This is useful if
your key has any special characters.

```moon
t = {
  [1 + 2]: "hello"
  "hello world": true
}

```

## Comprehensions

Comprehensions provide a convenient syntax for constructing a new table by
iterating over some existing object and applying an expression to its values.
There are two kinds of comprehensions: list comprehensions and table
comprehensions. They both produce Lua tables; _list comprehensions_ accumulate
values into an array-like table, and _table comprehensions_ let you set both
the key and the value on each iteration.

### List Comprehensions

The following creates a copy of the `items` table but with all the values
doubled.

```moon
items = { 1, 2, 3, 4 }
doubled = [item * 2 for i, item in ipairs items]
```

The items included in the new table can be restricted with a `when` clause:

```moon
iter = ipairs items
slice = [item for i, item in iter when i > 1 and i < 3]
```

Because it is common to iterate over the values of a numerically indexed table,
an `*` operator is introduced. The doubled example can be rewritten as:

```moon
doubled = [item * 2 for item in *items]
```

The `for` and `when` clauses can be chained as much as desired. The only
requirement is that a comprehension has at least one `for` clause.

Using multiple `for` clauses is the same as using nested loops:

```moon
x_coords = {4, 5, 6, 7}
y_coords = {9, 2, 3}

points = [{x,y} for x in *x_coords for y in *y_coords]
```

Numeric for loops can also be used in comprehensions:

```moon
evens = [i for i=1,100 when i % 2 == 0]
```

### Table Comprehensions

The syntax for table comprehensions is very similar, only differing by using `{` and
`}` and taking two values from each iteration.

This example makes a copy of the table`thing`:

```moon
thing = {
  color: "red"
  name: "fast"
  width: 123
}

thing_copy = {k,v for k,v in pairs thing}
```

Table comprehensions, like list comprehensions, also support multiple `for` and
`when` clauses. In this example we use a `when` clause to prevent the value
associated with the `color` key from being copied.

```moon
no_color = {k,v for k,v in pairs thing when k != "color"}
```

The `*` operator is also supported. Here we create a square root look up table
for a few numbers.

```moon
numbers = {1,2,3,4}
sqrts = {i, math.sqrt i for i in *numbers}
```

The key-value tuple in a table comprehension can also come from a single
expression, in which case the expression should return two values. The
first is used as the key and the second is used as the value:

In this example we convert an array of pairs to a table where the first item in
the pair is the key and the second is the value.

```moon
tuples = {{"hello", "world"}, {"foo", "bar"}}
tbl = {unpack tuple for tuple in *tuples}
```

### Slicing

A special syntax is provided to restrict the items that are iterated over when
using the `*` operator. This is equivalent to setting the iteration bounds and
a step size in a `for` loop.

Here we can set the minimum and maximum bounds, taking all items with indexes
between 1 and 5 inclusive:

```moon
slice = [item for item in *items[1,5]]
```

Any of the slice arguments can be left off to use a sensible default. In this
example, if the max index is left off it defaults to the length of the table.
This will take everything but the first element:

```moon
slice = [item for item in *items[2,]]
```

If the minimum bound is left out, it defaults to 1. Here we only provide a step
size and leave the other bounds blank. This takes all odd indexed items: (1, 3,
5, ...)

```moon
slice = [item for item in *items[,,2]]
```

## String Interpolation

You can mix expressions into string literals using `#{}` syntax.

```moon
print "I am #{math.random! * 100}% sure."
```
String interpolation is only available in double quoted strings.

## For Loop

There are two for loop forms, just like in Lua. A numeric one and a generic one:

```moon
for i = 10, 20
  print i

for k = 1,15,2 -- an optional step provided
  print k

for key, value in pairs object
  print key, value
```

The slicing and `*` operators can be used, just like with comprehensions:

```moon
for item in *items[2,4]
  print item
```

A shorter syntax is also available for all variations when the body is only a
single line:

```moon
for item in *items do print item

for j = 1,10,3 do print j
```

A for loop can also be used as an expression. The last statement in the body of
the for loop is coerced into an expression and appended to an accumulating
array table.

Doubling every even number:

```moon
doubled_evens = for i=1,20
  if i % 2 == 0
    i * 2
  else
    i
```

You can also filter values by combining the for loop expression with the
[`continue`](#continue) statement.

For loops at the end of a function body are not accumulated into a table for a
return value (Instead the function will return `nil`). Either an explicit
`return` statement can be used, or the loop can be converted into a list
comprehension.

```moon
func_a = -> for i=1,10 do i
func_b = -> return for i=1,10 do i

print func_a! -- prints nil
print func_b! -- prints table object
```

This is done to avoid the needless creation of tables for functions that don't
need to return the results of the loop.

## While Loop

The while loop also comes in two variations:

```moon
i = 10
while i > 0
  print i
  i -= 1

while running == true do my_function!
```

Like for loops, the while loop can also be used an expression. Additionally,
for a function to return the accumulated value of a while loop, the statement
must be explicitly returned.

## Continue

A `continue` statement can be used to skip the current iteration in a loop.

```moon
i = 0
while i < 10
  continue if i % 2 == 0
  print i
```
`continue` can also be used with loop expressions to prevent that iteration
from accumulating into the result. This examples filters the array table into
just even numbers:

```moon
my_numbers = {1,2,3,4,5,6}
odds = for x in *my_numbers
  continue if x % 2 == 1
  x
```

## Conditionals

```moon
have_coins = false
if have_coins
  print "Got coins"
else
  print "No coins"
```

A short syntax for single statements can also be used:

```moon
have_coins = false
if have_coins then print "Got coins" else print "No coins"
```

Because if statements can be used as expressions, this can also be written as:

```moon
have_coins = false
print if have_coins then "Got coins" else "No coins"
```

Conditionals can also be used in return statements and assignments:

```moon
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
```

The opposite of `if` is `unless`:

```moon
unless os.date("%A") == "Monday"
  print "it is not Monday!"
```

```moon
print "You're lucky!" unless math.random! > 0.1
```

### With Assignment

`if` and `elseif` blocks can take an assignment in place of a conditional
expression. Upon evaluating the conditional, the assignment will take place and
the value that was assigned to will be used as the conditional expression. The
assigned variable is only in scope for the body of the conditional, meaning it
is never available if the value is not truthy.

```moon
if user = database.find_user "moon"
  print user.name
```

```moon
if hello = os.getenv "hello"
  print "You have hello", hello
elseif world = os.getenv "world"
  print "you have world", world
else
  print "nothing :("
```

## Line Decorators

For convenience, the for loop and if statement can be applied to single
statements at the end of the line:

```moon
print "hello world" if name == "Rob"
```

And with basic loops:

```moon
print "item: ", item for item in *items
```

## Switch

The switch statement is shorthand for writing a series of if statements that
check against the same value. Note that the value is only evaluated once. Like
if statements, switches can have an else block to handle no matches. Comparison
is done with the `==` operator.

```moon
name = "Dan"
switch name
  when "Robert"
    print "You are Robert"
  when "Dan", "Daniel"
    print "Your name, it's Dan"
  else
    print "I don't know about your name"
```

A switch `when` clause can match against multiple values by listing them out
comma separated.

Switches can be used as expressions as well, here we can assign the result of
the switch to a variable:

```moon
b = 1
next_number = switch b
  when 1
    2
  when 2
    3
  else
    error "can't count that high!"
```

We can use the `then` keyword to write a switch's `when` block on a single line.
No extra keyword is needed to write the else block on a single line.

```moon
msg = switch math.random(1, 5)
  when 1 then "you are lucky"
  when 2 then "you are almost lucky"
  else "not so lucky"
```

It is worth noting the order of the case comparison expression. The case's
expression is on the left hand side. This can be useful if the case's
expression wants to overwrite how the comparison is done by defining an `eq`
metamethod.

## Object Oriented Programming

In these examples, the generated Lua code may appear overwhelming. It is best
to focus on the meaning of the MoonScript code at first, then look into the Lua
code if you wish to know the implementation details.

A simple class:

```moon
class Inventory
  new: =>
    @items = {}

  add_item: (name) =>
    if @items[name]
      @items[name] += 1
    else
      @items[name] = 1
```

A class is declared with a `class` statement followed by a table-like
declaration where all of the methods and properties are listed.

The `new` property is special in that it will become the constructor.

Notice how all the methods in the class use the fat arrow function syntax. When
calling methods on a instance, the instance itself is sent in as the first
argument. The fat arrow handles the creation of a `self` argument.

The `@` prefix on a variable name is shorthand for `self.`. `@items` becomes
`self.items`.

Creating an instance of the class is done by calling the name of the class as a
function.

```moon
inv = Inventory!
inv\add_item "t-shirt"
inv\add_item "pants"
```

Because the instance of the class needs to be sent to the methods when they are
called, the <code>\\</code> operator is used.

All properties of a class are shared among the instances. This is fine for
functions, but for other types of objects, undesired results may occur.

Consider the example below, the `clothes` property is shared amongst all
instances, so modifications to it in one instance will show up in another:

```moononly
class Person
  clothes: {}
  give_item: (name) =>
    table.insert @clothes, name

a = Person!
b = Person!

a\give_item "pants"
b\give_item "shirt"

-- will print both pants and shirt
print item for item in *a.clothes
```

The proper way to avoid this problem is to create the mutable state of the
object in the constructor:

```moononly
class Person
  new: =>
    @clothes = {}
```

### Inheritance

The `extends` keyword can be used in a class declaration to inherit the
properties and methods from another class.

```moon
class BackPack extends Inventory
  size: 10
  add_item: (name) =>
    if #@items > size then error "backpack is full"
    super name
```

Here we extend our Inventory class, and limit the amount of items it can carry.

In this example, we don't define a constructor on the subclass, so the parent
class' constructor is called when we make a new instance. If we did define a
constructor then we can use the [`super`](#super) method to call the parent
constructor.

Whenever a class inherits from another, it sends a message to the parent class
by calling the method `__inherited` on the parent class if it exists. The
function receives two arguments, the class that is being inherited and the
child class.

```moononly
class Shelf
  @__inherited: (child) =>
    print @__name, "was inherited by", child.__name

-- will print: Shelf was inherited by Cupboard
class Cupboard extends Shelf
```

### Super

`super` is a special keyword that can be used in two different ways: It can be
treated as an object, or it can be called like a function. It only has special
functionality when inside a class.

When called as a function, it will call the function of the same name in the
parent class. The current `self` will automatically be passed as the first
argument. (As seen in the [inheritance](#inheritance) example above)

When `super` is used as a normal value, it is a reference to the parent class
object.

It can be accessed like any of object in order to retrieve values in the
parent class that might have been shadowed by the child class.

When the <code>\\</code> calling operator is used with `super`, `self` is inserted as the
first argument instead of the value of `super` itself. When using `.` to
retrieve a function, the raw function is returned.

A few examples of using `super` in different ways:

```moon
class MyClass extends ParentClass
  a_method: =>
    -- the following have the same effect:
    super "hello", "world"
    super\a_method "hello", "world"
    super.a_method self, "hello", "world"

    -- super as a value is equal to the parent class:
    assert super == ParentClass
```

`super` can also be used on left side of a [Function Stub](#function_stubs).
The only major difference is that instead of the resulting function being bound
to the value of `super`, it is bound to `self`.

### Types

Every instance of a class carries its type with it. This is stored in the
special `__class` property. This property holds the class object. The class
object is what we call to build a new instance. We can also index the class
object to retrieve class methods and properties.

```moon
b = BackPack!
assert b.__class == BackPack

print BackPack.size -- prints 10
```
### Class Objects

The class object is what we create when we use a `class` statement. The class
object is stored in a variable of the same name of the class.

The class object can be called like a function in order to create new
instances. That's how we created instances of classes in the examples above.

A class is made up of two tables. The class table itself, and the *base* table. The
*base* is used as the metatable for all the instances. All properties listed in
the class declaration are placed in the *base*.

The class object's metatable reads properties from the base if they don't exist
in the class object. This means we can access functions and properties directly
from the class.

It is important to note that assigning to the class object does not assign into
the *base*, so it's not a valid way to add new methods to instances. Instead
the *base* must explicitly be changed. See the `__base` field below.

The class object has a couple special properties:

The name of the class as when it was declared is stored as a string in the
`__name` field of the class object.

```moon
print BackPack.__name -- prints Backpack
```

The *base* object is stored in `__base`. We can modify this table to add
functionality to instances that have already been created and ones that are yet
to be created.

If the class extends from anything, the parent class object is stored in
`__parent`.

### Class Variables

We can create variables directly in the class object instead of in the *base*
by using `@` in the front of the property name in a class declaration.

```moononly
class Things
  @some_func: => print "Hello from", @__name

Things\some_func!

-- class variables not visible in instances
assert Things().some_func == nil

```

In expressions, we can use `@@` to access a value that is stored in the
`__class` of `self`.  Thus, `@@hello` is shorthand for `self.__class.hello`.

```moononly
class Counter
  @count: 0

  new: =>
    @@count += 1

Counter!
Counter!

print Counter.count -- prints 2
```

The calling semantics of `@@` are similar to `@`. Calling a `@@` name will pass
the class in as the first argument using Lua's colon syntax.

```moon
@@hello 1,2,3,4
```
### Class Declaration Statements

In the body of a class declaration, we can have normal expressions in addition
to key/value pairs. In this context, `self` is equal to the class object.

Here is an alternative way to create a class variable compared to what's
described above:

```moon
class Things
  @class_var = "hello world"

```

These expressions are executed after all the properties have been added to the
*base*.

All variables declared in the body of the class are local to the classes
properties. This is convenient for placing private values or helper functions
that only the class methods can access:


```moononly
class MoreThings
  secret = 123
  log = (msg) -> print "LOG:", msg

  some_method: =>
    log "hello world: " .. secret

```

### `@` and `@@` Values

When `@` and `@@` are prefixed in front of a name they represent, respectively,
that name accessed in `self` and `self.__class`.

If they are used all by themselves, they are aliases for `self` and
`self.__class`.

```moon
assert @ == self
assert @@ == self.__class
```

For example, a quick way to create a new instance of the same class from an
instance method using `@@`:

```moon
some_instance_method = (...) => @@ ...
```


### Class Expressions

The `class` syntax can also be used as an expression which can be assigned to a
variable or explicitly returned.

```moononly
x = class Bucket
  drops: 0
  add_drop: => @drops += 1
```

### Anonymous classes

The name can be left out when declaring a class. The `__name` attribute will be
`nil`, unless the class expression is in an assignment. The name on the left
hand side of the assignment is used instead of `nil`.


```moononly
BigBucket = class extends Bucket
  add_drop: => @drops += 10

assert Bucket.__name == "BigBucket"
```

You can even leave off the body, meaning you can write a blank anonymous class
like this:

```moononly
x = class
```

## Export Statement

Because all assignments to variables that are not lexically visible will
be declared as local, special syntax is required to declare a variable globally.

The export keyword makes it so any following assignments to the specified names
will not be assigned locally.

```moon
export var_name, var_name2
var_name, var_name3 = "hello", "world"
```

This is especially useful when declaring what will be externally visible in a
module:

```moon
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
```

Assignment can be combined with the export keyword to assign to global
variables directly:

```moon
export some_number, message_str = 100, "hello world"
```

Additionally, a class declaration can be prefixed with the export keyword in
order to export it.

Export will have no effect if there is already a local variable of the same
name in scope.

### Export All & Export Proper

The `export` statement can also take special symbols `*` and `^`.

`export *` will cause any name declared after the statement to be exported in the
current scope. `export ^` will export all proper names, names that begin with a
capital letter.

## Local Statement

Sometimes you want to declare a variable name before the first time you assign
it. The `local` statement can be used to do that.

In this example we declare the variable `a` in the outer scope so its value
can be accessed after the `if` statement. If there was no `local` statement then
`a` would only be accessible inside the `if` statement.

```moon
local a
if something
  a = 1
print a
```

`local` can also be used to shadow existing variables for the rest of a scope.

```moon
x = 10
if something
  local x
  x = 12
print x -- prints 10
```

When you have one function that calls another, you typically order them such
that the second function can access the first. If both functions happen to
call each other, then you must forward declare the names:

```moon
local first, second

first = ->
  second!

second = ->
  first!
```

The same problem occurs with declaring classes and regular values too.

Because forward declaring is often better than manually ordering your assigns,
a special form of `local` is provided:

```moon
local *

first = ->
  print data
  second!

second = ->
  first!

data = {}
```

`local *` will forward declare all names below it in the current scope.

Similarly to [`export`](#export_all_and_export_proper) one more special form is
provided, `local ^`. This will forward declare all names that begin with a
capital letter.

## Import Statement

Often you want to bring some values from a table into the current scope as
local variables by their name. The import statement lets us accomplish this:

```moon
import insert from table
```

The multiple names can be given, each separated by a comma:

```moon
import C, Ct, Cmt from lpeg
```

Sometimes a function requires that the table be sent in as the first argument
(when using the <code>\\</code> syntax). As a shortcut, we can prefix the name
with a <code>\\</code> to bind it to that table:

```moon
-- some object
my_module =
  state: 100
  add: (value) =>
    self.state + value

import \add from my_module

print add 22 -- equivalent to calling my_module\add 22
```

When handing multiple imports you can substitute the comma with a newline and
any amount of whitespace. When working with a lot of imports you might write
something like this:

```moon
import
  assert_csrf
  assert_timezone
  not_found
  require_login
  from require "helpers"
```

## With Statement

A common pattern involving the creation of an object is calling a series of
functions and setting a series of properties immediately after creating it.

This results in repeating the name of the object multiple times in code, adding
unnecessary noise. A common solution to this is to pass a table in as an
argument which contains a collection of keys and values to overwrite. The
downside to this is that the constructor of this object must support this form.

The `with` block helps to alleviate this. Within a `with` block we can use a
special statements that begin with either `.` or <code>\\</code> which represent
those operations applied to the object we are using `with` on.

For example, we work with a newly created object:

```moon
with Person!
  .name = "Oswald"
  \add_relative my_dad
  \save!
  print .name
```

The `with` statement can also be used as an expression which returns the value
it has been giving access to.

```moon
file = with File "favorite_foods.txt"
  \set_encoding "utf8"
```

Or...

```moon
create_person = (name,  relatives) ->
  with Person!
    .name = name
    \add_relative relative for relative in *relatives

me = create_person "Leaf", {dad, mother, sister}
```
In this usage, `with` can be seen as a special form of the K combinator.

The expression in the `with` statement can also be an assignment, if you want
to give a name to the expression.

```moon
with str = "Hello"
  print "original:", str
  print "upper:", \upper!
```

## Do

When used as a statement, `do` works just like it does in Lua.

```moon
do
  var = "hello"
  print var
print var -- nil here
```

MoonScript's `do` can also be used an expression . Allowing you to combine
multiple lines into one. The result of the `do` expression is the last
statement in its body.


```moon
counter = do
  i = 0
  ->
    i += 1
    i

print counter!
print counter!
```

```moon
tbl = {
  key: do
    print "assigning key!"
    1234
}
```

## Destructuring Assignment

Destructuring assignment is a way to quickly extract values from a table by
their name or position in array based tables.

Typically when you see a table literal, `{1,2,3}`, it is on the right hand side
of an assignment because it is a value. Destructuring assignment swaps the role
of the table literal, and puts it on the left hand side of an assign
statement.

This is best explained with examples. Here is how you would unpack the first
two values from a table:

```moon
thing = {1,2}

{a,b} = thing
print a,b
```

In the destructuring table literal, the key represents the key to read from the
right hand side, and the value represents the name the read value will be
assigned to.

```moon
obj = {
  hello: "world"
  day: "tuesday"
  length: 20
}

{hello: hello, day: the_day} = obj
print hello, the_day
```

This also works with nested data structures as well:

```moon
obj2 = {
  numbers: {1,2,3,4}
  properties: {
    color: "green"
    height: 13.5
  }
}

{numbers: {first, second}} = obj2
print first, second, color
```
If the destructuring statement is complicated, feel free to spread it out over
a few lines. A slightly more complicated example:

```moon
{
  numbers: { first, second }
  properties: {
    color: color
  }
} = obj2
```

It's common to extract values from at table and assign them the local variables
that have the same name as the key. In order to avoid repetition we can use the
`:` prefix operator:

```moon
{:concat, :insert} = table
```

This is effectively the same as import, but we can rename fields we want to
extract by mixing the syntax:

```moon
{:mix, :max, random: rand } = math
```

### Destructuring In Other Places

Destructuring can also show up in places where an assignment implicitly takes
place. An example of this is a `for` loop:


```moon
tuples = {
  {"hello", "world"}
  {"egg", "head"}
}

for {left, right} in *tuples
  print left, right
```

We know each element in the array table is a two item tuple, so we can unpack
it directly in the names clause of the for statement using a destructure.


## Function Stubs

It is common to pass a function from an object around as a value, for example,
passing an instance method into a function as a callback. If the function
expects the object it is operating on as the first argument then you must
somehow bundle that object with the function so it can be called properly.

The function stub syntax is a shorthand for creating a new closure function
that bundles both the object and function. This new function calls the wrapped
function in the correct context of the object.

Its syntax is the same as calling an instance method with the <code>\\</code> operator but
with no argument list provided.

```moon
my_object = {
  value: 1000
  write: => print "the value:", @value
}

run_callback = (func) ->
  print "running callback..."
  func!

-- this will not work:
-- the function has to no reference to my_object
run_callback my_object.write

-- function stub syntax
-- lets us bundle the object into a new function
run_callback my_object\write
```

## The Using Clause; Controlling Destructive Assignment

While lexical scoping can be a great help in reducing the complexity of the
code we write, things can get unwieldy as the code size increases. Consider
the following snippet:

```moon
i = 100

-- many lines of code...

my_func = ->
  i = 10
  while i > 0
    print i
    i -= 1

my_func!

print i -- will print 0
```


In `my_func`, we've overwritten the value of `i` mistakenly. In this example it
is quite obvious, but consider a large, or foreign code base where it isn't
clear what names have already been declared.

It would be helpful to say which variables from the enclosing scope we intend
on change, in order to prevent us from changing others by accident.

The `using` keyword lets us do that. `using nil` makes sure that no closed
variables are overwritten in assignment. The `using` clause is placed after the
argument list in a function, or in place of it if there are no arguments.

```moon
i = 100

my_func = (using nil) ->
  i = "hello" -- a new local variable is created here

my_func!
print i -- prints 100, i is unaffected
```


Multiple names can be separated by commas. Closure values can still be
accessed, they just cant be modified:

```moon
tmp = 1213
i, k = 100, 50

my_func = (add using k,i) ->
  tmp = tmp + add -- a new local tmp is created
  i += tmp
  k += tmp

my_func(22)
print i,k -- these have been updated
```

## Misc.

### Implicit Returns on Files

By default, a file will also implicitly return like a function. This is useful
for writing modules, where you can put your module's table as the last
statement in the file so it is returned when loaded with `require`.

### Writing Modules

Lua 5.2 has removed the `module` function for creating modules. It is
recommended to return a table instead when defining a module.

We can cleanly define modules by using the shorthand hash table key/value
syntax:

```moonret

MY_CONSTANT = "hello"

my_function = -> print "the function"
my_second_function = -> print "another function"

{ :my_function, :my_second_function, :MY_CONSTANT}
```

If you need to forward declare your values so you can access them regardless of
their written order you can add `local *` to the top of your file.

# License (MIT)

    Copyright (C) 2017 by Leaf Corcoran

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


