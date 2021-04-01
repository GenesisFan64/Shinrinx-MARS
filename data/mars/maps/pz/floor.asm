MarsMapPz_floor:
		dc.w 0,0
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/floor_vert.bin"
.face:		binclude "data/mars/maps/pz/floor_face.bin"
.vrtx:		binclude "data/mars/maps/pz/floor_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/floor_mtrl.asm"
