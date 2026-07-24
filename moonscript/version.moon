
version = "0.7.0"

{
  version: version,
  print_version: ->
    -- MOON_BUILD_INFO is only set by the static binary wrappers (bin/binaries)
    if build = MOON_BUILD_INFO
      print "MoonScript version #{version} (static build)"
      print "Runtime: #{jit and jit.version or build.lua}"
      print "Commit: #{build.commit}"
      print "Built: #{build.time}"
    else
      print "MoonScript version #{version}"
}
