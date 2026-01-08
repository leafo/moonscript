LUA ?= lua5.1
LUA_VERSION = $(shell $(LUA) -e 'print(_VERSION:match("%d%.%d"))')
LUAROCKS = luarocks --lua-version=$(LUA_VERSION)
LUA_PATH_MAKE = $(shell $(LUAROCKS) path --lr-path);./?.lua;./?/init.lua
LUA_CPATH_MAKE = $(shell $(LUAROCKS) path --lr-cpath);./?.so

LUA_SRC_VERSION ?= 5.1.5
LPEG_VERSION ?= 1.0.2

.PHONY: test local build watch lint count show test_binary

build:
	LUA_PATH='$(LUA_PATH_MAKE)' LUA_CPATH='$(LUA_CPATH_MAKE)' $(LUA) bin/moonc moon/ moonscript/
	echo "#!/usr/bin/env lua" > bin/moon
	$(LUA) bin/moonc -p bin/moon.moon >> bin/moon
	echo "-- vim: set filetype=lua:" >> bin/moon


# This will rebuild MoonScript from the (hopefully working) system installation of moonc
build_from_system:
	moonc moon/ moonscript/
	echo "#!/usr/bin/env lua" > bin/moon
	moonc -p bin/moon.moon >> bin/moon
	echo "-- vim: set filetype=lua:" >> bin/moon

show:
	# LUA $(LUA)
	# LUA_VERSION $(LUA_VERSION)
	# LUAROCKS $(LUAROCKS)
	# LUA_PATH_MAKE $(LUA_PATH_MAKE)
	# LUA_CPATH_MAKE $(LUA_CPATH_MAKE)

test: build
	busted

build_test_outputs: build
	BUILD=1 busted spec/lang_spec.moon

local: build
	LUA_PATH='$(LUA_PATH_MAKE)' LUA_CPATH='$(LUA_CPATH_MAKE)' $(LUAROCKS) make --local moonscript-dev-1.rockspec

watch:
	moonc moon/ moonscript/ && moonc -w moon/ moonscript/

lint:
	moonc -l moonscript moon bin

count:
	wc -l $$(git ls-files | grep 'moon$$') | sort -n | tail

# Binary build targets for local verification (Linux only)
lua-$(LUA_SRC_VERSION)/src/liblua.a:
	curl -L -O https://www.lua.org/ftp/lua-$(LUA_SRC_VERSION).tar.gz
	tar -xzf lua-$(LUA_SRC_VERSION).tar.gz
	cd lua-$(LUA_SRC_VERSION)/src && make liblua.a MYCFLAGS=-DLUA_USE_POSIX

lpeg-$(LPEG_VERSION)/lptree.c:
	curl -L -o lpeg.tar.gz https://www.inf.puc-rio.br/~roberto/lpeg/lpeg-$(LPEG_VERSION).tar.gz
	tar -xzf lpeg.tar.gz

dist/moon: lua-$(LUA_SRC_VERSION)/src/liblua.a lpeg-$(LPEG_VERSION)/lptree.c
	mkdir -p dist
	gcc -static -o dist/moon -Ilua-$(LUA_SRC_VERSION)/src/ bin/binaries/moon.c lpeg-$(LPEG_VERSION)/lpvm.c lpeg-$(LPEG_VERSION)/lpcap.c lpeg-$(LPEG_VERSION)/lptree.c lpeg-$(LPEG_VERSION)/lpcode.c lpeg-$(LPEG_VERSION)/lpprint.c lua-$(LUA_SRC_VERSION)/src/liblua.a -lm -ldl

test_binary: dist/moon
	dist/moon -h
	dist/moon -e 'print "hello world"'
