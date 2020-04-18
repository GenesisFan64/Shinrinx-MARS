; ====================================================================
; ----------------------------------------------------------------
; SH2 ROM user data
; 
; If your data is too much for SDRAM, place it here.
; Note that this section will be gone if the Genesis side is
; perfoming a DMA ROM-to-VDP Transfer (setting RV=1)
; ----------------------------------------------------------------

		align 4
TEST_MODEL:	binclude "data/mars/models/rubia_head.bin"	; dc.w faces,vertices
		dc.l .vert,.face,.vrtx,.mtrl			; dc.l vertices, faces, vertex, material
.vert:		binclude "data/mars/models/rubia_vert.bin"
.face:		binclude "data/mars/models/rubia_face.bin"
.vrtx:		binclude "data/mars/models/rubia_vrtx.bin"
.mtrl:		include "data/mars/models/rubia_mtrl.asm"

		align 4
Textr_MagicalOjam:
		binclude "data/mars/models/mtrl/doremi_art.bin"
		align 4
Textr_TestTexture:
		binclude "data/mars/models/mtrl/rubia_art.bin"
		align 4
		
; WAV_LEFT:	binclude "data/mars/rom/L.wav",$2C,$100000
; WAV_LEFT_E:
; 		align 4
; WAV_RIGHT:	binclude "data/mars/rom/R.wav",$2C,$100000
; WAV_RIGHT_E:
; 		align 4
