zs = 128
x = 1

z = zs
for a in range(zs*2):
	zd = z
	if zd == 0:
		zd = 1
	print( (x/zd) )
	z -= 1
