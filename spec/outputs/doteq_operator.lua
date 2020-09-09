local a = {
  b = function()
    return {
      c = {
        d = {
          e = 'f'
        }
      }
    }
  end
}
a = a.b()
a = a.c.d
a = a.e
assert(a == 'f')
a = {
  b = {
    c = {
      d = {
        e = 'f'
      }
    }
  }
}
a.b = a.b.c.d
a = a.b.e
return assert(a == 'f')