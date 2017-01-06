# MoonScript

[![MoonScript](http://leafo.net/dump/sailormoonscript.png)](http://moonscript.org)

[![Build Status](https://travis-ci.org/leafo/moonscript.svg?branch=master)](https://travis-ci.org/leafo/moonscript) [![Build status](https://ci.appveyor.com/api/projects/status/f5prpi4wvytul290/branch/binaries?svg=true)](https://ci.appveyor.com/project/leafo/moonscript/branch/binaries)


MoonScript is a programmer friendly language that compiles into
[Lua](http://www.lua.org/). It gives you the power of the fastest scripting
language combined with a rich set of features. It runs on Lua 5.1 and above,
including alternative runtimes like LuaJIT.

See <http://moonscript.org>.

Online demo/compiler at <http://moonscript.org/compiler>.

## Running Tests

Tests are written in MoonScript and use [Busted](http://olivinelabs.com/busted/).
In order to run the tests you must have MoonScript and [Loadkit](https://github.com/leafo/loadkit) installed.

To run tests, execute from the root directory:

```bash
busted
```

Writing specs is a bit more complicated. Check out [the spec writing guide](spec/README.md).


## Binaries

Precompiled versions of MoonScript are provided for Windows. You can find them
in the [GitHub releases page](https://github.com/leafo/moonscript/releases).
(Scroll down to the `win32-` tags.

The build code can be found in the [`binaries`
branch](https://github.com/leafo/moonscript/tree/binaries)

## Editor Support

* [Vim](https://github.com/leafo/moonscript-vim)
* [Textadept](https://github.com/leafo/moonscript-textadept)
* [Sublime/Textmate](https://github.com/leafo/moonscript-tmbundle)
* [Emacs](https://github.com/k2052/moonscript-mode)

## License (MIT)

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
