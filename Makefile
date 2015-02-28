.PHONY: test local compile watch lint

test:
	busted -p "_spec.moon$$"

local: compile
	luarocks make --local moonscript-dev-1.rockspec

global:
	sudo luarocks make moonscript-dev-1.rockspec

compile:
	lua5.1 bin/moonc moon/ moonscript/

watch:
	moonc moon/ moonscript/ && moonc -w moon/ moonscript/

lint:
	moonc -l moonscript moon
