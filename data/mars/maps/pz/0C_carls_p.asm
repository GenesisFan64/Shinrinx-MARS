MarsMapPz_0C_carls_p:
		dc.w 16,2871
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/0C_carls_p_vert.bin"
.face:		binclude "data/mars/maps/pz/0C_carls_p_face.bin"
.vrtx:		binclude "data/mars/maps/pz/0C_carls_p_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/0C_carls_p_mtrl.asm"
		align 4
