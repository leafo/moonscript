VERSION=$(lua -e 'io.stdout:write(require"moonscript.version".version)')
FILE=moonscript-${VERSION}.zip

[ -f "$FILE" ] && rm "$FILE"

zip "$FILE" moonscript.dll lua51.dll *.exe LICENSE README.txt

echo "Wrote $FILE"