-- busted helper (busted --helper=spec/use_slow_parser.moon) that runs the
-- suite against the pure Lua parser in place of the native C module. busted
-- loads moonscript, and with it the native parser, before helpers run, so
-- the package.loaded entry must be replaced as well
slow = dofile "moonscript/parse/slow.lua"
package.loaded["moonscript.parse.native"] = slow
package.preload["moonscript.parse.native"] = -> slow
