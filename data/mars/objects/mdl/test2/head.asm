MarsObj_test2:
		dc.w 9,28
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/objects/mdl/test2/vert.bin"
.face:		binclude "data/mars/objects/mdl/test2/face.bin"
.vrtx:		binclude "data/mars/objects/mdl/test2/vrtx.bin"
.mtrl:		include "data/mars/objects/mdl/test2/mtrl.asm"
		align 4