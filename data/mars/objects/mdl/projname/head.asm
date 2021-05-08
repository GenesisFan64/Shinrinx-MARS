MarsObj_projname:
		dc.w 399,443
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/objects/mdl/projname/vert.bin"
.face:		binclude "data/mars/objects/mdl/projname/face.bin"
.vrtx:		binclude "data/mars/objects/mdl/projname/vrtx.bin"
.mtrl:		include "data/mars/objects/mdl/projname/mtrl.asm"
		align 4