MarsObj_test3:
		dc.w 21,36
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/objects/mdl/test3/vert.bin"
.face:		binclude "data/mars/objects/mdl/test3/face.bin"
.vrtx:		binclude "data/mars/objects/mdl/test3/vrtx.bin"
.mtrl:		include "data/mars/objects/mdl/test3/mtrl.asm"
		align 4