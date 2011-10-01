local x = {
  val = 100,
  hello = function(self)
    return print(self.val)
  end
}
local fn = (function()
  local _base_0 = x
  local _fn_0 = _base_0.val
  return function(...)
    return _fn_0(_base_0, ...)
  end
end)()
print(fn())
print(x:val())