MarsObj_smok2:
		dc.w 1,4
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/objects/mdl/smok2/vert.bin"
.face:		binclude "data/mars/objects/mdl/smok2/face.bin"
.vrtx:		binclude "data/mars/objects/mdl/smok2/vrtx.bin"
.mtrl:		include "data/mars/objects/mdl/smok2/mtrl.asm"
		align 4