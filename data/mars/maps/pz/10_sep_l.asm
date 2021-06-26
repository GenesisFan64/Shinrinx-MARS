MarsMapPz_10_sep_l:
		dc.w 20,3135
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/10_sep_l_vert.bin"
.face:		binclude "data/mars/maps/pz/10_sep_l_face.bin"
.vrtx:		binclude "data/mars/maps/pz/10_sep_l_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/10_sep_l_mtrl.asm"
		align 4
