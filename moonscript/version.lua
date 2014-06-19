local version = "0.2.6"
return {
  version = version,
  print_version = function()
    return print("MoonScript version " .. tostring(version))
  end
}
