MarsObj_intro:
		dc.w 2,8
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/objects/mdl/intro/vert.bin"
.face:		binclude "data/mars/objects/mdl/intro/face.bin"
.vrtx:		binclude "data/mars/objects/mdl/intro/vrtx.bin"
.mtrl:		include "data/mars/objects/mdl/intro/mtrl.asm"
		align 4
