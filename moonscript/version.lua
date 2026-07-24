local version = "0.6.0"
return {
  version = version,
  print_version = function()
    do
      local build = MOON_BUILD_INFO
      if build then
        print("MoonScript version " .. tostring(version) .. " (static build)")
        print("Runtime: " .. tostring(jit and jit.version or build.lua))
        print("Commit: " .. tostring(build.commit))
        return print("Built: " .. tostring(build.time))
      else
        return print("MoonScript version " .. tostring(version))
      end
    end
  end
}
