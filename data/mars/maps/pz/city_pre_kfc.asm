MarsMapPz_city_pre_kfc:
		dc.w 434,1001
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/city_pre_kfc_vert.bin"
.face:		binclude "data/mars/maps/pz/city_pre_kfc_face.bin"
.vrtx:		binclude "data/mars/maps/pz/city_pre_kfc_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/city_pre_kfc_mtrl.asm"
		align 4
