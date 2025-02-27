# MoonScript

[![MoonScript](https://leafo.net/dump/sailormoonscript.png)](https://moonscript.org)


[![spec](https://github.com/leafo/moonscript/workflows/spec/badge.svg)](https://github.com/leafo/moonscript/actions?query=workflow%3Aspec) [![Build status](https://ci.appveyor.com/api/projects/status/f5prpi4wvytul290/branch/binaries?svg=true)](https://ci.appveyor.com/project/leafo/moonscript/branch/binaries)


[![](https://leafo.net/dump/twitch-banner.svg)](https://www.twitch.tv/moonscript)

MoonScript is a programmer friendly language that compiles into
[Lua](https://www.lua.org/). It gives you the power of the fastest scripting
language combined with a rich set of features. It runs on Lua 5.1 and above,
including alternative runtimes like LuaJIT.

See <https://moonscript.org>.

Online demo/compiler at <https://moonscript.org/compiler>.

## Join Our Community

We have a Discord for those interested in MoonScript and related projects. You can join us here: <https://discord.gg/Y75ZXrD>

## Contributing

MoonScript is a self-hosted compiler, meaning it's written in MoonScript itself. When contributing, please follow the following guidelines:

1. Edit `.moon` files, never modify the alongside `.lua` files directly
2. After making changes to `.moon` files, run the compiler to regenerate the corresponding `.lua` files
3. Both `.moon` and `.lua` files are included in the repository to ensure that:
   - Users can install and use MoonScript without having to compile it themselves
   - The compiler bootstrapping process works consistently

It's helpful to have a separate installation of MoonScript should you break
something and you need to re-build the MoonScript with a working version of
MoonScript. You can check out the repo in another directory, or install it
using LuaRocks to have a separate working version.

## Running Tests

Tests are written in MoonScript and use [Busted](https://olivinelabs.com/busted/).
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

Copyright (C) 2025 by Leaf Corcoran

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
