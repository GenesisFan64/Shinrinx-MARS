; ====================================================================
; ----------------------------------------------------------------
; SH2 ROM user data
; 
; If your data is too much for SDRAM, place it here.
; Note that this section will be gone if the Genesis side is
; perfoming a DMA ROM-to-VDP Transfer (setting RV=1)
; ----------------------------------------------------------------

		align 4
TEST_MODEL:	binclude "data/mars/models/cube_head.bin"	; dc.w faces,vertices
		dc.l .vert,.face,.vrtx,.mtrl			; dc.l vertices, faces, vertex, material
.vert:		binclude "data/mars/models/cube_vert.bin"
.face:		binclude "data/mars/models/cube_face.bin"
.vrtx:		binclude "data/mars/models/cube_vrtx.bin"
.mtrl:		include "data/mars/models/cube_mtrl.asm"

		align 4
Textr_Yui:
		binclude "data/mars/models/mtrl/yui_art.bin"
		align 4
Textr_TestTexture:
		binclude "data/mars/models/mtrl/rubia_art.bin"
		align 4
Textr_cubeleds:
		binclude "data/mars/models/mtrl/semf_art.bin"
		align 4
Textr_grass:
		binclude "data/mars/models/mtrl/grass_art.bin"
		align 4
		
; WAV_LEFT:	binclude "data/mars/L.wav",$2C,$140000
; WAV_LEFT_E:
; 		align 4
; WAV_RIGHT:	binclude "data/mars/R.wav",$2C,$140000
; WAV_RIGHT_E:
; 		align 4
