MarsMapPz_04_inters:
		dc.w 16,1128
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/04_inters_vert.bin"
.face:		binclude "data/mars/maps/pz/04_inters_face.bin"
.vrtx:		binclude "data/mars/maps/pz/04_inters_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/04_inters_mtrl.asm"
		align 4
