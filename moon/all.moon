
-- insert all moon library functions into requiring scope

export moon
moon = moon or {}
moon.inject = true
require "moon.init"

