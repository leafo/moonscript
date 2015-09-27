
# MoonScript spec guide

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

Code running in Busted will have the system install take precedence over the
loaded version. That means that if you `require "moonscript.base"` for a test,
you won't get the local copy.

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


`with_dev`'s require function will load the `.lua` files in the local
directory, not the `moon` ones. You're responsible for compiling them first
before running the tests.

You might do

```bash
$ make compile_system; busted
```

> `make compile_system` is a makefile task included in the repo that will build
> MoonScript in the current directory with the version installed to the system

