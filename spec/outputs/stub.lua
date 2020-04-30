local x = {
  val = 100,
  hello = function(self)
    return print(self.val)
  end
}
local fn
do
  local _base_0 = x
  local _fn_0 = _base_0.val
  fn = function(...)
    return _fn_0(_base_0, ...)
  end
end
print(fn())
print(x:val())
do
  local _base_0 = hello(...)
  local _fn_0 = _base_0.world
  x = function(...)
    return _fn_0(_base_0, ...)
  end
end
