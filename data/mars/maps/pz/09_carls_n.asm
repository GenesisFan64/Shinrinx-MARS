MarsMapPz_09_carls_n:
		dc.w 38,2429
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/09_carls_n_vert.bin"
.face:		binclude "data/mars/maps/pz/09_carls_n_face.bin"
.vrtx:		binclude "data/mars/maps/pz/09_carls_n_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/09_carls_n_mtrl.asm"
		align 4
