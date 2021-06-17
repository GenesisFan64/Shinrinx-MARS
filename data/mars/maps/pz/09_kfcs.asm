MarsMapPz_09_kfcs:
		dc.w 24,2631
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/09_kfcs_vert.bin"
.face:		binclude "data/mars/maps/pz/09_kfcs_face.bin"
.vrtx:		binclude "data/mars/maps/pz/09_kfcs_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/09_kfcs_mtrl.asm"
		align 4
