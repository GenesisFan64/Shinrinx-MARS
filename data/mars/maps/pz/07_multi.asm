MarsMapPz_07_multi:
		dc.w 30,2427
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/07_multi_vert.bin"
.face:		binclude "data/mars/maps/pz/07_multi_face.bin"
.vrtx:		binclude "data/mars/maps/pz/07_multi_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/07_multi_mtrl.asm"
		align 4
