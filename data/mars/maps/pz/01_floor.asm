MarsMapPz_01_floor:
		dc.w 16,25
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/01_floor_vert.bin"
.face:		binclude "data/mars/maps/pz/01_floor_face.bin"
.vrtx:		binclude "data/mars/maps/pz/01_floor_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/01_floor_mtrl.asm"
		align 4
