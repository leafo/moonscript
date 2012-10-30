local a
a = function()
  do
    local _with_0 = something
    print(_with_0.hello)
    print(hi)
    print("world")
    return _with_0
  end
end
do
  local _with_0 = leaf
  _with_0.world()
  _with_0.world(1, 2, 3)
  local g = _with_0.what.is.this
  _with_0.hi(1, 2, 3)
  _with_0:hi(1, 2).world(2323)
  _with_0:hi("yeah", "man")
  _with_0.world = 200
end
local zyzyzy
do
  local _with_0 = something
  _with_0.set_state("hello world")
  zyzyzy = _with_0
end
local x = 5 + (function()
  do
    local _with_0 = Something()
    _with_0:write("hello world")
    return _with_0
  end
end)()
x = {
  hello = (function()
    do
      local _with_0 = yeah
      _with_0:okay()
      return _with_0
    end
  end)()
}
do
  local _with_0 = foo
  local _ = _with_0:prop("something").hello
  _with_0.prop:send(one)
  _with_0.prop:send(one)
  return _with_0
end