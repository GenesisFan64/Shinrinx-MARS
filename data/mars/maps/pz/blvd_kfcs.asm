MarsMapPz_blvd_kfcs:
		dc.w 433,1001
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/blvd_kfcs_vert.bin"
.face:		binclude "data/mars/maps/pz/blvd_kfcs_face.bin"
.vrtx:		binclude "data/mars/maps/pz/blvd_kfcs_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/blvd_kfcs_mtrl.asm"
		align 4
