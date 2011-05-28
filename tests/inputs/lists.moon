
hi = [x*2 for _, x in ipairs{1,2,3,4}]

items = {1,2,3,4,5,6}

mm = [@x for @x in ipairs items]

[z for z in ipairs items when z > 4]

rad = [{a} for a in ipairs {
   1,2,3,4,5,6,
} when good_number a]

