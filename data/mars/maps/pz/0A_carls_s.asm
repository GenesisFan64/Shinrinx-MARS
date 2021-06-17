MarsMapPz_0A_carls_s:
		dc.w 32,2467
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/0A_carls_s_vert.bin"
.face:		binclude "data/mars/maps/pz/0A_carls_s_face.bin"
.vrtx:		binclude "data/mars/maps/pz/0A_carls_s_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/0A_carls_s_mtrl.asm"
		align 4
