MarsMapPz_city_inters:
		dc.w 16,1026
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/city_inters_vert.bin"
.face:		binclude "data/mars/maps/pz/city_inters_face.bin"
.vrtx:		binclude "data/mars/maps/pz/city_inters_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/city_inters_mtrl.asm"
		align 4
