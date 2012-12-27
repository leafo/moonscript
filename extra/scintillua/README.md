# MoonScript for [scintillua][1]

MoonScript syntax file for [SciTE][2] written in Lua for [scintillua][1].

## Windows Binary

Windows users can get a all-included package ready for MoonScript Development:

<http://moonscript.org/scite/>

If you already have a ScITE installation, or are on another platform, follow
the directions below.

## Installation

Install SciTE, then [install scintillua][1].

Put `moonscript.properties` in in your ScITE installation folder or user
properties folder.

Copy the entire contents of the `lexers` folder in this repository into your
scintillua `lexers` folder.

In your `lexers` folder edit `lpeg.properties`, add to the end:

    file.patterns.moonscript=*.moon
    lexer.$(file.patterns.moonscript)=lpeg_moonscript

Optionally, enable the Moon theme, find `lexer.peg.color.theme` in the same
file and change it to:

    lexer.lpeg.color.theme=moon

  [1]: http://foicica.com/scintillua/ "scintillua"
  [2]: http://www.scintilla.org/SciTE.html "SciTE"
  
