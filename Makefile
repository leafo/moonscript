
test::
	moonc test2.moon && TIME=1 busted test2.lua

local:
	luarocks make --local moonscript-dev-1.rockspec

global:
	sudo luarocks make moonscript-dev-1.rockspec

compile:
	bin/moonc moon/ moonscript/


compile_global:
	moonc moon/ moonscript/

watch:
	moonc -w moon/ moonscript/
