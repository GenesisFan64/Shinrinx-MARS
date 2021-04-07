; --------------------------------------------------------
; Palettes
; --------------------------------------------------------

Palette_Intro:	binclude "data/mars/objects/mtrl/intro_pal.bin"
		align 4
Palette_Map:	binclude "data/mars/maps/mtrl/marscity_pal.bin"
		align 4

; --------------------------------------------------------
; Objects
; --------------------------------------------------------

		include "data/mars/maps/map_marscity.asm"
		align 4
		include "data/mars/objects/mdl/intro/head.asm"
		align 4
