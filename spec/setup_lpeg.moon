
lpeg = os.getenv "LPEG"

if lpeg == "lulpeg"
  print "Using LuLPeg"
  os.execute "curl -O 'https://raw.githubusercontent.com/pygy/LuLPeg/master/lulpeg.lua'"
  package.loaded.lpeg = require("lulpeg")
