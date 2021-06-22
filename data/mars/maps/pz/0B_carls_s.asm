MarsMapPz_0B_carls_s:
		dc.w 25,2857
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/0B_carls_s_vert.bin"
.face:		binclude "data/mars/maps/pz/0B_carls_s_face.bin"
.vrtx:		binclude "data/mars/maps/pz/0B_carls_s_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/0B_carls_s_mtrl.asm"
		align 4
