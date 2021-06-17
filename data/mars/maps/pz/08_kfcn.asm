MarsMapPz_08_kfcn:
		dc.w 173,2598
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/08_kfcn_vert.bin"
.face:		binclude "data/mars/maps/pz/08_kfcn_face.bin"
.vrtx:		binclude "data/mars/maps/pz/08_kfcn_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/08_kfcn_mtrl.asm"
		align 4
