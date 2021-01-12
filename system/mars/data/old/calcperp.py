import sys

i=1
a=0

d7 = 512
output_file = open(sys.argv[1],"wb")
while d7:
	d7 -= 1
	
	#value=(160)/i
	#i -= 0.55
	#b = int(value)
	#output_file.write( bytes([
		#(b>>24)&0xFF,
		#b>>16&0xFF,
		#b>>8&0xFF,
		#b&0xFF
		#])
		#)
		
	#print("\t\tdc.l",int(value))
	
	a = i
	if a == 0:
		print("ZERO")
		a = 1
	 
	value=((320/2)*8)/a
	if value == 0:
		value = 1
	i += 0.1 #0.048 stable
	b = int(round(value, 1))
	output_file.write( bytes([
		(b>>24)&0xFF,
		b>>16&0xFF,
		b>>8&0xFF,
		b&0xFF
		])
		)
	
	print("\t\tdc.l",int(b))
	
output_file.close()
