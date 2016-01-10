{
  target: "reference/command_line"
  template: "reference"
  title: "Command Line Tools"
  short_name: "command_line"
}

# Command Line Tools

Two tools are installed with MoonScript, `moon` and `moonc`.

`moonc` is for compiling MoonScript code to Lua.
`moon` is for running MoonScript code directly.

## `moon`

`moon` can be used to run MoonScript files directly from the command line,
without needing a separate compile step. All MoonScript files are compiled in
memory as they are executed.

```bash
$ moon my_script.moon
```

Any MoonScript files that are required will also be compiled on demand as they
are loaded.

When an error occurs during runtime, the stack trace is rewritten to give line
numbers from the original `.moon` file.

If you want to disable [error rewriting](#error_rewriting), you can pass the
`-d` flag. A full list of flags can be seen by passing the `-h` or `--help`
flag.

### Error Rewriting

Runtime errors are given special attention when running code using the `moon`
command line tool. Because code is written in MoonScript but executed as Lua,
errors that happen during runtime report Lua line numbers. This can make
debugging less than ideal.

In order to solve this problem MoonScript builds up a table of line number
mappings, allowing the runtime to calculate what line of MoonScript generated
the line of Lua that triggered the error.

Consider the following file with a bug (note the invalid `z` variable):

```moon
add_numbers = (x,y) -> x + z  -- 1
print add_numbers 10,0        -- 2
```

The following error is generated:

    moon: scrap.moon:1(3): attempt to perform arithmetic on global 'z' (a nil value)
    stack traceback:
      scrap.moon:1(3): in function 'add_numbers'
      scrap.moon:2(5): in main chunk


Notice how next to the file name there are two numbers. The first number is the
rewritten line number. The number in the parentheses is the original Lua line
number.

The error in this example is being reported on line 1 of the `moon` file, which
corresponds to line 3 of the generated Lua code. The entire stack trace is rewritten in
addition to the error message.

### Code Coverage

`moon` lets you run a MoonScript file while keeping track of which lines
are executed with the `-c` flag.

For example, consider the following `.moon` file:

```moononly
-- test.moon
first = ->
  print "hello"

second = ->
  print "world"

first!
```

We can execute and get a glance of which lines ran:

```bash
$ moon -c test.moon
```

The following output is produced:

    ------| @cool.moon
         1| -- test.moon
    *    2| first = ->
    *    3|   print "hello"
         4|
    *    5| second = ->
         6|   print "world"
         7|
    *    8| first!
         9|

The star next to the line means that it was executed. Blank lines are not
considered when running so by default they don't get marked as executed.

## `moonc`

`moonc` is used for transforming MoonScript files into Lua files.
It takes a list of files, compiles them all, and creates the associated `.lua`
files in the same directories.

```bash
$ moonc my_script1.moon my_script2.moon ...
```

You can control where the compiled files are put using the `-t` flag, followed
by a directory.

`moonc` can also take a directory as an argument, and it will recursively scan
for all MoonScript files and compile them.

`moonc` can write to standard out by passing the `-p` flag.

The `-w` flag can be used to enable watch mode. `moonc` will stay running, and
watch for changes to the input files. If any of them change then they will be
compiled automatically.

A full list of flags can be seen by passing the `-h` or `--help` flag.

### Linter

`moonc` contains a [lint][1] tool for statically detecting potential problems
with code. The linter has two tests: detects accessed global variables,
detect unused declared variables. If the linter detects any issues with a file,
the program will exit with a status of `1`.

You can execute the linter with the `-l` flag. When the linting flag is
provided only linting takes place and no compiled code is generated.

The linter is compatible with the watch mode (see above) for automatic linting.

```bash
moonc -l file1.moon file2.moon
```

Like when compiling, you can also pass a directory as a command line argument
to recursively process all the `.moon` files.

#### Global Variable Checking

It's considered good practice to avoid using global variables and create local
variables for all the values referenced. A good case for not using global
variables is that you can analyize the code ahead of time without the need to
execute it to find references to undeclared variables.

MoonScript makes it difficult to declare global variables by forcing you to be
explicit with the `export` keyword, so it's a good candidate for doing this
kind of linting.

Consider the following program with a typo: (`my_number` is spelled wrong as
`my_nmuber` in the function)

```moononly
-- lint_example.moon
my_number = 1234

some_function = ->
  -- a contrived example with a small chance to pass
  if math.random() < 0.01
    my_nmuber + 10

some_function!
```

Although there is a bug in this code, it rarely happens during execution. It's
more likely to be missed during development and cause problems in the future.

Running the linter immediately identifies the problem:

```bash
$ moonc -l lint_example.moon
```

Outputs:

    ./lint_example.moon

    line 7: accessing global `my_nmuber`
    ==================================
    > 		my_nmuber + 10

#### Global Variable Whitelist

In most circumstances it's impossible to avoid using some global variables. For
example, to access any of the built in modules or functions you typically
access them globally.

For this reason a global variable whitelist is used. It's a list of global
variables that are allowed to be used. A default whitelist is provided that
contains all of Lua's built in functions and modules.

You can create your own entires in the whitelist as well. For example, the
testing framework [Busted](http://olivinelabs.com/busted) uses a collection of
global functions (like `describe`, `before_each`, `setup`) to make writing
tests easy.

It would be nice if we could allow all of those global functions to be called
for `.moon` files located in the `spec/` directory. We can do that by creating
a `lint_config` file.

`lint_config` is a regular MoonScript or Lua file that provides configuration
for the linter. One of those settings is `whitelist_globals`.

To create a configuration for Busted we might do something like this:

```moononly
-- lint_config.moon
{
  whitelist_globals: {
    ["spec/"]: {
      "it", "describe", "setup", "teardown",
      "before_each", "after_each", "pending"
    }
  }
}
```

Compile the file:

```bash
$ moonc lint_config.moon
```

Then run the linter on your entire project:

```bash
$ moonc -l .
```

The whitelisted global references in `spec/` will no longer raise notices.

The `whitelist_globals` property of the `lint_config` is a table where the keys
are Lua patterns that match file names, and the values are an array of globals
that are allowed.

Multiple patterns in `whitelist_globals` can match a single file, the union of
the allowed globals will be used when linting that file.

#### Unused Variable Assigns

Sometimes when debugging, refactoring, or just developing, you might leave
behind stray assignments that aren't actually necessary for the execution of
your code. It's good practice to clean them up to avoid any potential confusion
they might cause.

The unused assignment detector keeps track of any variables that are assigned,
and if they aren't accessed in within their available scope, they are reported
as an error.

Given the following code:

```moononly
a, b = 1, 2
print "hello", a
```

The linter will identify the problem:

    ./lint_example.moon

    line 1: assigned but unused `b`
    ===============================
    > a, b = 1, 2


Sometimes you need a name to assign to even though you know it will never be
accessed.  The linter will treat `_` as a special name that's allowed to be
written to but never accessed:

The following code would not produce any lint errors:

```moononly
item = {123, "shoe", "brown", 123}
_, name, _, count = unpack item
print name, count
```

  [1]: http://en.wikipedia.org/wiki/Lint_(software)

