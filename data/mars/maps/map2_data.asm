		dc.l .blocks
		binclude "data/mars/maps/map2_lay.bin"
		align 4
.blocks:
		dc.l MarsMapPz_city_floor
		dc.l MarsMapPz_city_main
		dc.l MarsMapPz_city_pre_kfc
		dc.l MarsMapPz_city_inters
		dc.l MarsMapPz_city_bridge
		dc.l MarsMapPz_city_septm
		dc.l MarsMapPz_city_multi_s
		dc.l MarsMapPz_city_kfc_n
		dc.l MarsMapPz_city_carls_s
		dc.l MarsMapPz_city_carls_n
		dc.l MarsMapPz_city_carls_r
		include "data/mars/maps/pz/city_floor.asm"
		include "data/mars/maps/pz/city_main.asm"
		include "data/mars/maps/pz/city_pre_kfc.asm"
		include "data/mars/maps/pz/city_inters.asm"
		include "data/mars/maps/pz/city_bridge.asm"
		include "data/mars/maps/pz/city_septm.asm"
		include "data/mars/maps/pz/city_multi_s.asm"
		include "data/mars/maps/pz/city_kfc_n.asm"
		include "data/mars/maps/pz/city_carls_s.asm"
		include "data/mars/maps/pz/city_carls_n.asm"
		include "data/mars/maps/pz/city_carls_r.asm"