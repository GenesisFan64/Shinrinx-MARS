MarsMapPz_0F_sept_lrd:
		dc.w 20,2972
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/0F_sept_lrd_vert.bin"
.face:		binclude "data/mars/maps/pz/0F_sept_lrd_face.bin"
.vrtx:		binclude "data/mars/maps/pz/0F_sept_lrd_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/0F_sept_lrd_mtrl.asm"
		align 4
		align 4