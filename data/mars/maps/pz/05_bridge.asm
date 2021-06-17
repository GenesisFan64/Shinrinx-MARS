MarsMapPz_05_bridge:
		dc.w 725,2345
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/05_bridge_vert.bin"
.face:		binclude "data/mars/maps/pz/05_bridge_face.bin"
.vrtx:		binclude "data/mars/maps/pz/05_bridge_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/05_bridge_mtrl.asm"
		align 4
