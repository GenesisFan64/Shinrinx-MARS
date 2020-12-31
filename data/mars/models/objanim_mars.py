# ======================================================================
# CHAN animation to MARS
# 
# STABLE
# 
# Usage:
# objtomars.py objname
# ======================================================================

import sys

# ======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

# ======================================================================
# -------------------------------------------------
# Start
# -------------------------------------------------

projectname   = sys.argv[1]
CONVERT_TEX=1

INCR_Y=0
if len(sys.argv) == 3:
  #CONVERT_TEX = sys.argv[2]
  INCR_Y = sys.argv[2]

model_file    = open("mdl/"+projectname+".chan","r")
out_anim      = open(projectname+"_anim.bin","wb")
vertex_list   = list()

# ======================================================================
# -------------------------------------------------
# Getting data
# -------------------------------------------------

scale=0x20000
reading=True
while reading:
  text=model_file.readline()
  #reading -= 1
  if text=="":
    reading=False
    break

  point = text.split("\t")
  x_pos = int(float(point[1])*scale)
  y_pos = int(float(point[2])*scale)*-1
  z_pos = int(float(point[3])*scale)*-1
  y_rot = int(float(point[4])*(scale*3))*-1
  x_rot = int(float(point[5])*(scale*3))*-1
  z_rot = int(float(point[6])*(scale*3))*-1
  
  out_anim.write( bytes([x_pos>>24&0xFF,x_pos>>16&0xFF,x_pos>>8&0xFF,x_pos&0xFF,
			 y_pos>>24&0xFF,y_pos>>16&0xFF,y_pos>>8&0xFF,y_pos&0xFF,
			 z_pos>>24&0xFF,z_pos>>16&0xFF,z_pos>>8&0xFF,z_pos&0xFF,
			 x_rot>>24&0xFF,x_rot>>16&0xFF,x_rot>>8&0xFF,x_rot&0xFF,
			 y_rot>>24&0xFF,y_rot>>16&0xFF,y_rot>>8&0xFF,y_rot&0xFF,
			 z_rot>>24&0xFF,z_rot>>16&0xFF,z_rot>>8&0xFF,z_rot&0xFF			 
			 ]) )
	
#======================================================================
# ----------------------------
# End
# ----------------------------

model_file.close()
out_anim.close()
