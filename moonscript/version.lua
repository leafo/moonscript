local version = "0.4.0"
return {
  version = version,
  print_version = function()
    return print("MoonScript version " .. tostring(version))
  end
}
