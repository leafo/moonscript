
test::
	busted -p "_spec.moon$$"

local: compile
	luarocks make --local moonscript-dev-1.rockspec

global:
	sudo luarocks make moonscript-dev-1.rockspec

compile::
	bin/moonc moon/ moonscript/


compile_global:
	moonc moon/ moonscript/

watch:
	moonc moon/ moonscript/ && moonc -w moon/ moonscript/
