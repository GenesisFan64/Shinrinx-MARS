MarsObj_smok:
		dc.w 1,4
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/objects/mdl/smok/vert.bin"
.face:		binclude "data/mars/objects/mdl/smok/face.bin"
.vrtx:		binclude "data/mars/objects/mdl/smok/vrtx.bin"
.mtrl:		include "data/mars/objects/mdl/smok/mtrl.asm"
		align 4