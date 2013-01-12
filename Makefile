
test::
	TIME=1 bin/moon test2.moon

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
