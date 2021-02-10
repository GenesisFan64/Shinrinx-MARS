#======================================================================
# PYTHON BASE
#======================================================================

import sys
import os.path

#======================================================================
# -------------------------------------------------
# Subs
# -------------------------------------------------
      
#======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

if len(sys.argv) == 1:
	print("ARGS: inputfile [pattnumloop]")
	exit()
	
if os.path.exists(sys.argv[1]) == False:
	print("File not found")
	exit()
	
MASTERNAME = sys.argv[1][:-3]
input_file = open(sys.argv[1],"rb")
out_patterns = open("../"+MASTERNAME+"_patt.bin","wb")
out_blocks   = open("../"+MASTERNAME+"_blk.bin","wb")

#======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

working=True

input_file.seek(0x20)
OrdNum = ord(input_file.read(1)) | (ord(input_file.read(1)) << 8)
InsNum = ord(input_file.read(1)) | (ord(input_file.read(1)) << 8)
SmpNum = ord(input_file.read(1)) | (ord(input_file.read(1)) << 8)
PatNum = ord(input_file.read(1)) | (ord(input_file.read(1)) << 8)

addr_BlockList = 0xC0
addr_PattList  = 0xC0+( (OrdNum) + (InsNum*4) + (SmpNum*4) )

#======================================================================
# -------------------------------------------------
# Start
# -------------------------------------------------

#$00 - $77  | notas
#$78 - $7F  | libres
#$FE        | note CUT (rest ===)
#$FF        | note OFF (FM: key off)

MAX_TIME = 0x7F				# MAX timer value
MAX_CHAN = 18				# MAX channels to use (limit: 63)
buff_Notes = [0]*(MAX_CHAN)		# mode, note, instr, volume, effects

# -------------------------------------------------
# build BLOCKS (pattern order)
# -------------------------------------------------
input_file.seek(addr_BlockList)
for b in range(0,OrdNum):
	a = ord(input_file.read(1))
	out_blocks.write(bytes([a]))

# -------------------------------------------------
# build Patterns
# -------------------------------------------------

addr_PattInc = 0					# OUT header counter
numof_Patt   = PatNum
out_patterns.write(bytes(numof_Patt*4))			# make room for pointers

while numof_Patt:
	# INPUT FILE: get pattern address
	input_file.seek(addr_PattList)
	addr_PattList += 4
	addr_CurrPat = ord(input_file.read(1)) | ord(input_file.read(1)) << 8 | ord(input_file.read(1)) << 16 | ord(input_file.read(1)) << 24
	input_file.seek(addr_CurrPat)

	sizeof_Patt = ord(input_file.read(1)) | ord(input_file.read(1)) << 8
	sizeof_Rows = ord(input_file.read(1)) | ord(input_file.read(1)) << 8
	input_file.seek(4,True)
	b = out_patterns.tell()
	out_patterns.seek(addr_PattInc)
	out_patterns.write(bytes([b&0xFF,(b>>8)&0xFF]))
	out_patterns.write(bytes([sizeof_Rows&0xFF,(sizeof_Rows>>8)&0xFF]))
	out_patterns.seek(b)
	
	# ---------------------------
	# read pattern head
	# ---------------------------
	set_RowEnd = False
	timerOut = 0
	while sizeof_Rows:
		a = ord(input_file.read(1))

		# If 0x00 end-of-row / timer
		if a == 0:
			if set_RowEnd == True:				# if this 0x00 is end-of-row
				set_RowEnd = False
				out_patterns.write(bytes(1))
			else:						# if this 0x00 is repeated
				if timerOut != 0:
					out_patterns.seek(-1,True)
				out_patterns.write(bytes([timerOut&0x7F]))
				timerOut += 1
				if timerOut > MAX_TIME:
					timerOut = 0
			sizeof_Rows -= 1

		# If not 0x00, note data
		else:
			timerOut = 0					# reset timer
			b = (a-1) & 0x3F				# channelnumber-1 & 0x3F
			
			# if controlbit (0x80) active, next byte
			# contains NEW note bits
			if (a & 128) != 0:
				a = 0xC0 | b
				out_patterns.write(bytes([a&0xFF]))
				a = ord(input_file.read(1))
				buff_Notes[b] = a
				out_patterns.write(bytes([a&0xFF]))
			else:
				a = 0x80 | b
				out_patterns.write(bytes([a&0xFF]))
				
			
			a = buff_Notes[b]
			if (a & 1) != 0:
				out_patterns.write(bytes([ord(input_file.read(1))&0xFF]))
			if (a & 2) != 0:
				out_patterns.write(bytes([ord(input_file.read(1))&0xFF]))
			if (a & 4) != 0:
				out_patterns.write(bytes([ord(input_file.read(1))&0xFF]))
			if (a & 8) != 0:
				out_patterns.write(bytes([ord(input_file.read(1))&0xFF]))
				out_patterns.write(bytes([ord(input_file.read(1))&0xFF]))
			set_RowEnd = True # set next 0x00 as end-of-row
			
	# Next block
	addr_PattInc += 4
	numof_Patt -= 1
		
# ----------------------------
# End
# ----------------------------

input_file.close()
out_patterns.close()    
