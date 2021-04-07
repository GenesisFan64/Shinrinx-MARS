MarsMapPz_blvd_main:
		dc.w 186,256
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/blvd_main_vert.bin"
.face:		binclude "data/mars/maps/pz/blvd_main_face.bin"
.vrtx:		binclude "data/mars/maps/pz/blvd_main_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/blvd_main_mtrl.asm"
