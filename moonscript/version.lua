local version = "0.3.1"
return {
  version = version,
  print_version = function()
    return print("MoonScript version " .. tostring(version))
  end
}
