local version = "0.5.0"
return {
  version = version,
  print_version = function()
    return print("MoonScript version " .. tostring(version))
  end
}
