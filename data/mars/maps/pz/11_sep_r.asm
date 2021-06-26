MarsMapPz_11_sep_r:
		dc.w 20,3165
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/11_sep_r_vert.bin"
.face:		binclude "data/mars/maps/pz/11_sep_r_face.bin"
.vrtx:		binclude "data/mars/maps/pz/11_sep_r_vrtx.bin"
.mtrl:		include "data/mars/maps/pz/11_sep_r_mtrl.asm"
		align 4
		align 4