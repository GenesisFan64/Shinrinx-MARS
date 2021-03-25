MarsMapPz_road_main:
		dc.w 78,95
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/road_main_vert.bin"
.face:		binclude "data/mars/maps/pz/road_main_face.bin"
.vrtx:		binclude "data/mars/maps/pz/road_main_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/road_main_mtrl.asm"
		align 4