local version = "0.2.5"
return {
  version = version,
  print_version = function()
    return print("MoonScript version " .. tostring(version))
  end
}
