; ====================================================================
; ----------------------------------------------------------------
; SH2 SDRAM user data
; 
; This data is stored on SDRAM, it's always available to use
; and can be re-writeable
; Put small sections of data like palettes or small models
; ----------------------------------------------------------------

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
