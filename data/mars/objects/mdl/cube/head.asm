MarsObj_cube:
		dc.w 87,137
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/objects/mdl/cube/vert.bin"
.face:		binclude "data/mars/objects/mdl/cube/face.bin"
.vrtx:		binclude "data/mars/objects/mdl/cube/vrtx.bin"
.mtrl:		include "data/mars/objects/mdl/cube/mtrl.asm"
		align 4