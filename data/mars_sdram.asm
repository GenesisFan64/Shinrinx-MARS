; ====================================================================
; ----------------------------------------------------------------
; SH2 SDRAM user data
; 
; This data is stored on SDRAM, it's always available to use
; and can be re-writeable
; ----------------------------------------------------------------

		align 4
TEST_MODEL:	binclude "data/mars/models/cube_head.bin"	; dc.w faces,vertices
		dc.l .vert,.face,.vrtx,.mtrl			; dc.l vertices, faces, vertex, material
.vert:		binclude "data/mars/models/cube_vert.bin"
.face:		binclude "data/mars/models/cube_face.bin"
.vrtx:		binclude "data/mars/models/cube_vrtx.bin"
.mtrl:		include "data/mars/models/cube_mtrl.asm"
		align 4
Palette_Puyo:	binclude "data/mars/models/mtrl/marscity_pal.bin"
		align 4
		
CAMERA_ANIM:	binclude "data/mars/models/camera_anim.bin"
		align 4
