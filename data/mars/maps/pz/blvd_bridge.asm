MarsMapPz_blvd_bridge:
		dc.w 605,1991
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/blvd_bridge_vert.bin"
.face:		binclude "data/mars/maps/pz/blvd_bridge_face.bin"
.vrtx:		binclude "data/mars/maps/pz/blvd_bridge_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/blvd_bridge_mtrl.asm"
		align 4