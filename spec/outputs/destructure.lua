do
  local a, b
  do
    local _obj_0 = hello
    a, b = _obj_0[1], _obj_0[2]
  end
  local c
  do
    local _obj_0 = hello
    a, b, c = _obj_0[1][1], _obj_0[2], _obj_0[3][1]
  end
  local hello, world
  do
    local _obj_0 = value
    hello, world = _obj_0.hello, _obj_0.world
  end
end
do
  local no, thing
  do
    local _obj_0 = world
    no, thing = _obj_0.yes, _obj_0[1]
  end
  local a, b, c, d
  do
    local _obj_0 = yeah
    a, b, c, d = _obj_0.a, _obj_0.b, _obj_0.c, _obj_0.d
  end
  a = one[1]
  local _ = two
  b = one[1]
  c = nil
  d = one[1]
  local e = two
  local x = one
  local y
  y = two[1]
  local xx, yy = 1, 2
  do
    local _obj_0 = {
      xx,
      yy
    }
    yy, xx = _obj_0[1], _obj_0[2]
  end
  local f, g
  do
    local _obj_0 = tbl
    a, b, c, d, e, f, g = _obj_0[1], _obj_0.b, _obj_0[2], _obj_0.d, _obj_0[3], _obj_0.f, _obj_0[4]
  end
end
do
  local futurists = {
    sculptor = "Umberto Boccioni",
    painter = "Vladimir Burliuk",
    poet = {
      name = "F.T. Marinetti",
      address = {
        "Via Roma 42R",
        "Bellagio, Italy 22021"
      }
    }
  }
  local name, street, city
  name, street, city = futurists.poet.name, futurists.poet.address[1], futurists.poet.address[2]
end
do
  self.world = x[1]
  do
    local _obj_0 = x
    a.b, c.y, func().z = _obj_0[1], _obj_0[2], _obj_0[3]
  end
  self.world = x.world
end
do
  local thing = {
    {
      1,
      2
    },
    {
      3,
      4
    }
  }
  for _index_0 = 1, #thing do
    local _des_0 = thing[_index_0]
    local x, y
    x, y = _des_0[1], _des_0[2]
    print(x, y)
  end
end
do
  do
    local _with_0 = thing
    local a, b
    a, b = _with_0[1], _with_0[2]
    print(a, b)
  end
end
do
  local thing = nil
  do
    local _des_0 = thing
    if _des_0 then
      local a
      a = _des_0[1]
      print(a)
    else
      print("nothing")
    end
  end
  local thang = {
    1,
    2
  }
  do
    local _des_0 = thang
    if _des_0 then
      local a, b
      a, b = _des_0[1], _des_0[2]
      print(a, b)
    end
  end
  do
    local _des_0 = thing
    if _des_0 then
      local a, b
      a, b = _des_0[1], _des_0[2]
      print(a, b)
    else
      do
        local _des_1 = thang
        if _des_1 then
          local c, d
          c, d = _des_1[1], _des_1[2]
          print(c, d)
        else
          print("NO")
        end
      end
    end
  end
end
do
  local z = "yeah"
  local a, b, c
  a, b, c = z[1], z[2], z[3]
end
do
  local a, b, c
  do
    local _obj_0 = z
    a, b, c = _obj_0[1], _obj_0[2], _obj_0[3]
  end
end
local _
_ = function(z)
  local a, b, c
  a, b, c = z[1], z[2], z[3]
end
do
  local z = "oo"
  return function(k)
    local a, b, c
    a, b, c = z[1], z[2], z[3]
  end
end
