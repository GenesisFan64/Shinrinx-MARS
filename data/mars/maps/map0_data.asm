		dc.l .blocks
		binclude "data/mars/maps/map0_lay.bin"
		align 4
.blocks:
		dc.l MarsMapPz_city_floor,0
		dc.l MarsMapPz_blvd_main,0
		dc.l MarsMapPz_blvd_kfcs,0
		dc.l MarsMapPz_blvd_kfcn,0
		dc.l MarsMapPz_blvd_bridge,0
		include "data/mars/maps/pz/city_floor.asm"
		include "data/mars/maps/pz/blvd_main.asm"
		include "data/mars/maps/pz/blvd_kfcs.asm"
		include "data/mars/maps/pz/blvd_kfcn.asm"
		include "data/mars/maps/pz/blvd_bridge.asm"
