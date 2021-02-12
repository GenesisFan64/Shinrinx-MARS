; --------------------------------------------------------
; Palettes
; --------------------------------------------------------

Palette_Puyo:	binclude "data/mars/objects/mtrl/smok_pal.bin"
		align 4
Palette_Map:	binclude "data/mars/objects/mtrl/marscity_sdram_pal.bin"
		align 4
Textr_smok:
		binclude "data/mars/objects/mtrl/smok_art.bin"
		align 4
Textr_marscity:
		binclude "data/mars/objects/mtrl/marscity_sdram_art.bin"
		align 4
		
; --------------------------------------------------------
; Objects
; 
; Models, animations, and smaller textures
; --------------------------------------------------------

		include "data/mars/objects/mdl/test/head.asm"
		include "data/mars/objects/mdl/test2/head.asm"
		include "data/mars/objects/mdl/test3/head.asm"
		include "data/mars/objects/mdl/smok/head.asm"
		align 4

; --------------------------------------------------------
; Map layout
; --------------------------------------------------------

; center topleft is at X=6,Y=5 (actual center: X=7,Y=8)
TEST_LAYOUT:
 dc.l .blocks
 
;       0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F 
 dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0002,$0002,$0002,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ; 0
 dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0002,$0001,$0002,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ; 1
 dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0002,$0001,$0002,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ; 2
 dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0002,$0001,$0002,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ; 3
 dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0002,$0001,$0002,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ; 4
 dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0002,$0001,$0002,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ; 5
 dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0002,$0001,$0002,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ; 6
 dc.w $0002,$0002,$0002,$0002,$0002,$0002,$0002,$0001,$0002,$0002,$0002,$0002,$0002,$0002,$0002,$0000 ; 7
 dc.w $0002,$2001,$2001,$2001,$2001,$2001,$2001,$0003,$2001,$2001,$2001,$2001,$2001,$2001,$0002,$0000 ; 8
 dc.w $0002,$0002,$0002,$0002,$0002,$0002,$0002,$0001,$0002,$0002,$0002,$0002,$0002,$0002,$0002,$0000 ; 9
 dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0002,$0001,$0002,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ; A
 dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0002,$0001,$0002,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ; B
 dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0002,$0001,$0002,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ; C
 dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0002,$0001,$0002,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ; D
 dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0002,$0001,$0002,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ; E
 dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0002,$0002,$0002,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ; F

.blocks:
	dc.l MARSOBJ_TEST,0
	dc.l MARSOBJ_TEST2,0
	dc.l MARSOBJ_TEST3,0
.objects:
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	
	
; TEST_ANIMATION:	binclude "data/mars/objects/anim/cube_anim.bin"
; 		align 4
