MarsObj_intro_2:
		dc.w 199,215
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/objects/mdl/intro_2/vert.bin"
.face:		binclude "data/mars/objects/mdl/intro_2/face.bin"
.vrtx:		binclude "data/mars/objects/mdl/intro_2/vrtx.bin"
.mtrl:		include "data/mars/objects/mdl/intro_2/mtrl.asm"
		align 4