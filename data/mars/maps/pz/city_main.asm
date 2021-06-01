MarsMapPz_city_main:
		dc.w 198,304
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/city_main_vert.bin"
.face:		binclude "data/mars/maps/pz/city_main_face.bin"
.vrtx:		binclude "data/mars/maps/pz/city_main_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/city_main_mtrl.asm"
		align 4
