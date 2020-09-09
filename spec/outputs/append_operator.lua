local a = { }
print(#a)
a[#a + 1] = 'v'
a[#a + 1] = 'c'
for i, v in ipairs(a) do
  print(i, v)
end