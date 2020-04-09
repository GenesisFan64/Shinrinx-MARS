# ======================================================================
# OBJ TO MARS
# 
# STABLE
# ======================================================================

import sys

# -------------------------------------------------
# VALUE SIZES
# 
# Vertices: LONG
# Faces:    WORD
# Vertex:   WORD
# Header:   LONG (numof_vert, numof_faces)
# -------------------------------------------------

# ======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

SCALE_SIZE=20 #20 best
FROM_BLENDER=False #True

# ======================================================================
# -------------------------------------------------
# Start
# -------------------------------------------------

num_vert      = 0

projectname   = sys.argv[1]
if len(sys.argv) == 3:
	SCALE_SIZE = int(sys.argv[2])

list_vertices = list()
list_faces    = list()
model_file    = open("mdl/"+projectname+".obj","r")
material_file = open("mdl/"+projectname+".mtl","r")	# CHECK BELOW
out_vertices  = open(projectname+"_vert.bin","wb")	# vertices (points)
out_faces     = open(projectname+"_face.bin","wb")	# faces
out_vertex    = open(projectname+"_vrtx.bin","wb")	# texture vertex
out_head      = open(projectname+"_head.bin","wb")	# header

used_triangles= 0
used_quads    = 0
solidcolor    = 1
randomcolor   = 1
reading       = True
vertex_list   = list()

# ======================================================================
# -------------------------------------------------
# Getting data
# -------------------------------------------------

while reading:
  text=model_file.readline()
  if text=="":
    reading=False

  # ---------------------------
  # vertices
  # ---------------------------
  
  if text.find("v") == False: 
    a = text[2:]
    point = a.replace("\n","").split(" ")
    if point[0] != "":
      x=float(point[0])
      y=float(point[1])
      z=float(point[2])

      mars_x=int(x*SCALE_SIZE)*-1
      mars_z=int(z*SCALE_SIZE)*-1
      if FROM_BLENDER == True:		# Y pos
        mars_y=(int(y*SCALE_SIZE)*-1)+int((SCALE_SIZE/2))
      else:
        mars_y=int(y*SCALE_SIZE)*-1

      # LONG
      out_vertices.write( bytes([
	      mars_x >> 24 & 0xFF,
	      mars_x >> 16 & 0xFF,
	      mars_x >> 8 & 0xFF,
	      mars_x & 0xFF,
	      mars_y >> 24 & 0xFF,
	      mars_y >> 16 & 0xFF,
	      mars_y >> 8 & 0xFF,
	      mars_y & 0xFF,
	      mars_z >> 24 & 0xFF,
	      mars_z >> 16 & 0xFF,
	      mars_z >> 8 & 0xFF,
	      mars_z & 0xFF
	      ]) )
      num_vert += 1
	
  # ---------------------------
  # vertex
  # ---------------------------
  
  if text.find("vt") == False:
    a = text[2:]
    point = a.replace("\n","").split(" ")
    vertex_list.append(float(point[1]))
    vertex_list.append(float(point[2]))

    ## if needed later
    #x=float(point[1])
    #y=float(point[2])
    #mars_x=int(x)
    #mars_y=int(y)
    #out_vertex.write( bytes([
	      #mars_x >> 24 & 0xFF,
	      #mars_x >> 16 & 0xFF,
	      #mars_x >> 8 & 0xFF,
	      #mars_x & 0xFF,
	      #mars_y >> 24 & 0xFF,
	      #mars_y >> 16 & 0xFF,
	      #mars_y >> 8 & 0xFF,
	      #mars_y & 0xFF,
	      #]) )

  # ---------------------------
  # MATERIAL check
  # ---------------------------
  
  if text.find("usemtl") == False:
    material_file.seek(0)
    mtlname = text[7:].rstrip('\r\n')

    # MATERIAL FILE READ LOOP
    mtlread = True
    while mtlread:
      mtltext=material_file.readline()
      if mtltext=="":
        mtlread=False
    
      # Grab material section
      if mtltext.find("newmtl "+mtlname) == False:
        i = True
        while i:
          b = material_file.readline()
          if b=="":
            i=False
          if b.find("map_Kd") == False:
            a = b[7:].rstrip('\r\n')
            tex_file = open(a,"rb")

            # COPYPASTED
            tex_file.seek(1)
            color_type = ord(tex_file.read(1))
            image_type = ord(tex_file.read(1))

            if color_type == 1:
            	pal_start = ord(tex_file.read(1))
            	pal_start += ord(tex_file.read(1)) << 8
            	pal_len = ord(tex_file.read(1))
            	pal_len += ord(tex_file.read(1)) << 8
            	ignore_this = ord(tex_file.read(1))
            	has_pal = True
	
            if image_type == 1:
            	img_xstart = ord(tex_file.read(1))
            	img_xstart += ord(tex_file.read(1)) << 8
            	img_ystart = ord(tex_file.read(1))
            	img_ystart += ord(tex_file.read(1)) << 8
            	img_width = ord(tex_file.read(1))
            	img_width += ord(tex_file.read(1)) << 8
            	img_height = ord(tex_file.read(1))
            	img_height += ord(tex_file.read(1)) << 8
	
            	img_pixbits = ord(tex_file.read(1))
            	img_type = ord(tex_file.read(1)) 
            	if (img_type >> 5 & 1) == False:
            		print("ERROR: TOP LEFT images only")
            		quit()
            	has_img = True
            else:
            	print("IMAGE TYPE NOT SUPPORTED:",hex(image_type))
            	img_width = 32
            	img_height = 32

            #print(img_width,img_height)
            tex_file.close()

  # ---------------------------
  # Faces
  # 
  # Format might get changed
  # ---------------------------
  
  if text.find("f") == False:
    a = text[2:]
    point = a.split(" ")
    if len(point) == 3:
      x_curr=point[0].split("/")
      y_curr=point[1].split("/")
      z_curr=point[2].split("/")
      out_faces.write( bytes([0,3]) )      # POLYGON ID
      
      x=int(x_curr[0])-1
      y=int(y_curr[0])-1
      z=int(z_curr[0])-1
      outx_l = x >> 8 & 0xFF
      outx_r = x & 0xFF
      outy_l = y >> 8 & 0xFF
      outy_r = y & 0xFF
      outz_l = z >> 8 & 0xFF
      outz_r = z & 0xFF
      out_faces.write(bytes([
	      outx_l,outx_r,
	      outy_l,outy_r,
	      outz_l,outz_r,
	      ]))
      
      x=int(x_curr[1])-1
      y=int(y_curr[1])-1
      z=int(z_curr[1])-1
      outx_l = x >> 8 & 0xFF
      outx_r = x & 0xFF
      outy_l = y >> 8 & 0xFF
      outy_r = y & 0xFF
      outz_l = z >> 8 & 0xFF
      outz_r = z & 0xFF
      out_faces.write(bytes([
	      outx_l,outx_r,
	      outy_l,outy_r,
	      outz_l,outz_r,
	      ]))
      
      # TEXTURE POINTS
      used_triangles += 1
      
    # QUAD
    if len(point) == 4:
      x_curr=point[0].split("/")
      y_curr=point[1].split("/")
      z_curr=point[2].split("/")
      q_curr=point[3].split("/")
      out_faces.write( bytes([0,4]) )      # POLYGON ID

      x=int(x_curr[0])-1
      y=int(y_curr[0])-1
      z=int(z_curr[0])-1
      q=int(q_curr[0])-1
      outx_l = x >> 8 & 0xFF
      outx_r = x & 0xFF
      outy_l = y >> 8 & 0xFF
      outy_r = y & 0xFF
      outz_l = z >> 8 & 0xFF
      outz_r = z & 0xFF
      outq_l = q >> 8 & 0xFF
      outq_r = q & 0xFF
      out_faces.write(bytes([
	      outx_l,outx_r,
	      outy_l,outy_r,
	      outz_l,outz_r,
	      outq_l,outq_r,
	      ]))
      
      # TEXTURE POINTS
      x=int(x_curr[1])-1
      y=int(y_curr[1])-1
      z=int(z_curr[1])-1
      q=int(q_curr[1])-1
      outx_l = x >> 8 & 0xFF
      outx_r = x & 0xFF
      outy_l = y >> 8 & 0xFF
      outy_r = y & 0xFF
      outz_l = z >> 8 & 0xFF
      outz_r = z & 0xFF
      outq_l = q >> 8 & 0xFF
      outq_r = q & 0xFF
      out_faces.write(bytes([
	      outx_l,outx_r,
	      outy_l,outy_r,
	      outz_l,outz_r,
	      outq_l,outq_r,
	      ]))
      used_quads += 1

#======================================================================
# ----------------------------
# Vertex convert
# ----------------------------

cntr = len(vertex_list)
x_tx = 0
while cntr:
  x_l = int(img_width * vertex_list[x_tx])
  x_r = int(img_height * vertex_list[x_tx+1])
  #out_vertex.write( bytes([
  #x_l>>24&0xFF,x_l>>16&0xFF,x_l>>8&0xFF,x_l&0xFF,
  #x_r>>24&0xFF,x_r>>16&0xFF,x_r>>8&0xFF,x_r&0xFF]))
  out_vertex.write( bytes([
  x_l>>8&0xFF,x_l&0xFF,
  x_r>>8&0xFF,x_r&0xFF]))
  x_tx += 2
  cntr -= 2
	
      #x_tx=(int(x_curr[1])-1) * 2
      #y_tx=(int(y_curr[1])-1) * 2
      #z_tx=(int(z_curr[1])-1) * 2
      #q_tx=(int(q_curr[1])-1) * 2
      #x_l = int(img_width * vertex_list[x_tx])
      #x_r = int(img_height * vertex_list[x_tx+1])
      #y_l = int(img_width * vertex_list[y_tx])
      #y_r = int(img_height * vertex_list[y_tx+1])
      #z_l = int(img_width * vertex_list[z_tx])
      #z_r = int(img_height * vertex_list[z_tx+1])
      #q_l = int(img_width * vertex_list[q_tx])
      #q_r = int(img_height * vertex_list[q_tx+1])
      #print(y_r)
      #out_faces.write( bytes([
	      #x_l>>24&0xFF,x_l>>16&0xFF,x_l>>8&0xFF,x_l&0xFF,
	      #x_r>>24&0xFF,x_r>>16&0xFF,x_r>>8&0xFF,x_r&0xFF,
	      #y_l>>24&0xFF,y_l>>16&0xFF,y_l>>8&0xFF,y_l&0xFF,
	      #y_r>>24&0xFF,y_r>>16&0xFF,y_r>>8&0xFF,y_r&0xFF,
	      #z_l>>24&0xFF,z_l>>16&0xFF,z_l>>8&0xFF,z_l&0xFF,
	      #z_r>>24&0xFF,z_r>>16&0xFF,z_r>>8&0xFF,z_r&0xFF,
	      #q_l>>24&0xFF,q_l>>16&0xFF,q_l>>8&0xFF,q_l&0xFF,
	      #q_r>>24&0xFF,q_r>>16&0xFF,q_r>>8&0xFF,q_r&0xFF,
	      #]))
	      
#======================================================================
# ----------------------------
# End
# ----------------------------

out_head.write( bytes([
	num_vert >> 24 & 0xFF,
	num_vert >> 16 & 0xFF,
	num_vert >> 8 & 0xFF,
	num_vert & 0xFF,
	used_triangles+used_quads >> 24 & 0xFF,
	used_triangles+used_quads >> 16 & 0xFF,
	used_triangles+used_quads >> 8 & 0xFF,
	used_triangles+used_quads & 0xFF
	]) )
      
#print("Scaling is at",SCALE_SIZE,"%")
#print("Vertices:",num_vert)
#print("   Faces:",used_triangles+used_quads)
#print("Polygons:",used_triangles)
#print("   Quads:",used_quads)
#print("Done.")

model_file.close()
material_file.close()
out_vertices.close()
out_faces.close()
out_head.close()
out_vertex.close()
