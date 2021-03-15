MarsMapPz_test:
		dc.w 5,13
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/maps/pz/vert_test.bin"
.face:		binclude "data/mars/maps/pz/face_test.bin"
.vrtx:		binclude "data/mars/maps/pz/vrtx_test.bin"
.mtrl:		include "data/mars/maps/pz/mtrl_test.asm"
		align 4