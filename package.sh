VERSION=$(lua -e 'io.stdout:write(require"moonscript.version".version)')
FILE=moonscript-${VERSION}.zip

[ -f "$FILE" ] && rm "$FILE"

zip "$FILE" *.dll *.exe LICENSE README.txt

echo "Wrote $FILE"