
# MoonScript spec guide

## Testing the right code

Because MoonScript is written in MoonScript, and MoonScript specs are written
in MoonScript, you need to be aware of which copy of MoonScript is actually
executing the specs.

A system installed version of MoonScript is recommended to run the specs (and
for development). This means that you'll typically have two versions of
MoonScript available in the load path:

* The system version
* The version in the current directory

> A system install is recommended because you'll always want a functioning
> version of MoonScript to compile with in case you break your development
> version.

When developing you want to make ensure the tests are executing your changes in
the current directory, and not testing the system install.

Busted itself is MoonScript aware, so it means it should have a functional
MoonScript compiler in order to load the `.moon` test files. This should be the
system install. After booting your specs though, you would like to use the
current directory version of MoonScript to the test

Because by default Busted will have the system install take precedence over the
loaded version, running `require "moonscript.base"` within a test you won't get
the working directory version of the code that you should be testing.

The `with_dev` spec helper will ensure that any require calls within the spec
that ask for MoonScript modules. `with_dev` calls a setup and teardown that
replaces `_G.require` with a custom version.

You'll use it like this:

```moonscript
import with_dev from require "spec.helpers"
describe "moonscript.base", ->
  with_dev!

  it "should load code", ->
    -- the local version is loaded
    moonscript = require "moonscript"
    moonscript.load "print 12"
```

Note that `with_dev`'s `require` function will not use the MoonLoader, it will
only load the `.lua` files in the working directory directory, not the `moon`
ones. This means you must compile the working directory version of MoonScript
before running the tests.

There is a make task to conveniently do all of this:

```
make test
```

## Building syntax tests

The test suite has a series of *syntax* tests (`spec/lang_spec.moon`) that
consist of a bunch of `.moon` files and their expected output. These files
should capture a large range of syntax that can be verified to have the correct
output when you make changes to the language.

If you are adding new syntax, or changing the expected output, then these tests
will fail until you rebuild the expected outputs. You can do this by running
the syntax test suite with the `BUILD` environment variable set.

There is a make task to conveniently do this:

```
make build_test_outputs
```

## Performance timing

The syntax specs have performance timing collection built in. To get these
times run the test suite with the `TIME` environment variable set.

```
TIME=1 busted spec/lang_spec.moon
```

Any changes to the compiler should not introduce any substantial performance
decreases.



