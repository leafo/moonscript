local a = 'b'
local c = d;
(a(b))(c(d))
c = d.c;
(a(b))(c(d));
(c(d))(a(b))
local b
a, b = c, d
return (d(a))(c)