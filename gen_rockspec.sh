#!/bin/bash

for file in $(find moonscript moon | grep 'lua$'); do
	MODULE=$(echo $file | sed -e 's/\.lua$//' -e 's/\//./g' -e 's/\.init$//')
	echo "[\"$MODULE\"] = \"$file\","
done

echo '["moonscript.parse.native"] = { sources = {"moonscript/parse/native.c"} },'
