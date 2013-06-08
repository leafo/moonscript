-- install moon into global scope
moon = require "moon"
for k,v in pairs moon
  _G[k] = v
moon

