.PHONY: test local compile compile_system watch lint

test:
	busted

local: compile
	luarocks make --local moonscript-dev-1.rockspec

compile:
	lua5.1 bin/moonc moon/ moonscript/
	echo "#!/usr/bin/env lua" > bin/moon
	lua5.1 bin/moonc -p bin/moon.moon >> bin/moon
	echo "-- vim: set filetype=lua:" >> bin/moon

compile_system:
	moonc moon/ moonscript/
	echo "#!/usr/bin/env lua" > bin/moon
	moonc -p bin/moon.moon >> bin/moon
	echo "-- vim: set filetype=lua:" >> bin/moon

watch:
	moonc moon/ moonscript/ && moonc -w moon/ moonscript/

lint:
	moonc -l moonscript moon bin
