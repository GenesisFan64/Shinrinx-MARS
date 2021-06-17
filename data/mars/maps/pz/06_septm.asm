MarsMapPz_06_septm:
		dc.w 28,2384
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/06_septm_vert.bin"
.face:		binclude "data/mars/maps/pz/06_septm_face.bin"
.vrtx:		binclude "data/mars/maps/pz/06_septm_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/06_septm_mtrl.asm"
		align 4
