MarsMapPz_02_main:
		dc.w 206,324
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/02_main_vert.bin"
.face:		binclude "data/mars/maps/pz/02_main_face.bin"
.vrtx:		binclude "data/mars/maps/pz/02_main_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/02_main_mtrl.asm"
		align 4
