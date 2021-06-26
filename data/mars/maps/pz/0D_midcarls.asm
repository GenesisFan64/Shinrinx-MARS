MarsMapPz_0D_midcarls:
		dc.w 64,2955
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/0D_midcarls_vert.bin"
.face:		binclude "data/mars/maps/pz/0D_midcarls_face.bin"
.vrtx:		binclude "data/mars/maps/pz/0D_midcarls_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/0D_midcarls_mtrl.asm"
		align 4
