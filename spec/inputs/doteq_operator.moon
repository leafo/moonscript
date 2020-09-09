a = b: -> c: d: e: 'f'
a .= b!
a .= c.d
a .= e
assert a=='f'

a = b: c: d: e: 'f'
a.b .= c.d
a .= b.e
assert a=='f'
