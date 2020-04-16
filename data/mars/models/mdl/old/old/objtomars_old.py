#======================================================================
# OBJ TO MARS
# 
# STABLE
#======================================================================

#======================================================================
# -------------------------------------------------
# Subs
# -------------------------------------------------

#test_list = 2,3,1,-3,-2,-2
#print sorted(test_list)

#======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

SCALE_SIZE=50
TEXTURE_TEST=False

#======================================================================
# -------------------------------------------------
# Start
# -------------------------------------------------

used_triangles=0
used_quads=0
input_file   = open("test.obj","r")
out_vertices = open("vertices.asm","wb")
out_faces    = open("faces.asm","wb")
out_material = open("material.asm","wb")
out_material.write("LATER")

solidcolor=1
textureid=256
reading=True

while reading:
  text=input_file.readline()
  if text=="":
    reading=False
  
  if text.find("mtllib") == False:
    print "Material"
  if text.find("v") == False:
    #if labelnodesused == False:
      #out_vertices.write("@nodes:\n")
      #labelnodesused=True
      
    a = text[2:]
    point = a.split(" ")
    if point[0] != "":
      x=float(point[0])
      y=float(point[1])
      z=float(point[2])
      mars_x=int(x*SCALE_SIZE)*-1
      mars_y=int(y*SCALE_SIZE)*-1
      mars_z=int(z*SCALE_SIZE)*-1

      out_vertices.write(" dc.w ")
      out_vertices.write(str(mars_x))
      out_vertices.write(",")
      out_vertices.write(str(mars_y))
      out_vertices.write(",")
      out_vertices.write(str(mars_z))
      out_vertices.write("\n")
    
  if text.find("f") == False:
    #if labelfaceused == False:
      #out_faces.write("@faces:\n")
      #labelfaceused=True

    a = text[2:]
    point = a.split(" ")
    if len(point) == 3:
      x_chk=point[0].split("/")
      y_chk=point[1].split("/")
      z_chk=point[2].split("/")
      x=int(x_chk[0])-1
      y=int(y_chk[0])-1
      z=int(z_chk[0])-1
    
      out_faces.write(" dc.w 3\n")
      out_faces.write(" dc.w ")
      if TEXTURE_TEST == True:
	out_faces.write(str(textureid))
      else:
	out_faces.write(str(solidcolor))		#Texture ID from material
      out_faces.write("\n")
      solidcolor+=1
      if solidcolor == 255:
	solidcolor=1
	
      out_faces.write(" dc.w ")
      out_faces.write(str(x))
      out_faces.write(",")
      out_faces.write(str(y))
      out_faces.write(",")
      out_faces.write(str(z))
      out_faces.write("\n")
      used_triangles += 1
      
    if len(point) == 4:
      x_chk=point[0].split("/")
      y_chk=point[1].split("/")
      z_chk=point[2].split("/")
      q_chk=point[3].split("/")
      
      x=int(x_chk[0])-1
      y=int(y_chk[0])-1
      z=int(z_chk[0])-1
      q=int(q_chk[0])-1
      
      out_faces.write(" dc.w 4\n")
      out_faces.write(" dc.w ")
      if TEXTURE_TEST == True:
	out_faces.write(str(textureid))
      else:
	out_faces.write(str(solidcolor))		#Texture ID from material
      out_faces.write("\n")
      solidcolor+=1
      if solidcolor == 255:
	solidcolor=1
	
      out_faces.write(" dc.w ")
      out_faces.write(str(q))
      out_faces.write(",")
      out_faces.write(str(x))
      out_faces.write(",")
      out_faces.write(str(y))
      out_faces.write(",")
      out_faces.write(str(z))
      out_faces.write("\n")
      used_quads += 1
      
#======================================================================
# ----------------------------
# End
# ----------------------------

print "used triangles:",used_triangles
print "used quads:",used_quads
print "all faces:",used_triangles+used_quads
print "Done."
input_file.close()
out_vertices.close()
out_faces.close()
out_material.close()
