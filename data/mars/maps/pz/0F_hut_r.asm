MarsMapPz_0F_hut_r:
		dc.w 99,3105
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/0F_hut_r_vert.bin"
.face:		binclude "data/mars/maps/pz/0F_hut_r_face.bin"
.vrtx:		binclude "data/mars/maps/pz/0F_hut_r_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/0F_hut_r_mtrl.asm"
		align 4
