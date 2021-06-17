MarsObj_intro_1:
		dc.w 184,196
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/objects/mdl/intro_1/vert.bin"
.face:		binclude "data/mars/objects/mdl/intro_1/face.bin"
.vrtx:		binclude "data/mars/objects/mdl/intro_1/vrtx.bin"
.mtrl:		include "data/mars/objects/mdl/intro_1/mtrl.asm"
		align 4