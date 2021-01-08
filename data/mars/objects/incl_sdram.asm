; --------------------------------------------------------
; Palettes
; --------------------------------------------------------

Palette_Puyo:	binclude "data/mars/objects/mtrl/marscity_pal.bin"
		align 4
		
; --------------------------------------------------------
; Objects
; 
; Models, animations, and smaller textures
; --------------------------------------------------------

TEST_MODEL:	binclude "data/mars/objects/mdl/cube/head.bin"	; dc.w faces,vertices
		dc.l .vert,.face,.vrtx,.mtrl			; dc.l vertices, faces, vertex, material
.vert:		binclude "data/mars/objects/mdl/cube/vert.bin"
.face:		binclude "data/mars/objects/mdl/cube/face.bin"
.vrtx:		binclude "data/mars/objects/mdl/cube/vrtx.bin"
.mtrl:		include "data/mars/objects/mdl/cube/mtrl.asm"
		align 4

; TEST_ANIMATION:	binclude "data/mars/objects/anim/cube_anim.bin"
; 		align 4
