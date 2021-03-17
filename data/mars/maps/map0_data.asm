		dc.l .blocks
		binclude "data/mars/maps/map0_lay.bin"
		align 4
.blocks:
		dc.l MarsMapPz_road_main,0
		include "data/mars/maps/pz/road_main.asm"
