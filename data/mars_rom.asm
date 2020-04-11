; ====================================================================
; ----------------------------------------------------------------
; SH2 ROM user data
; 
; If your data is too much for SDRAM, place it here.
; Note that this section will be gone if the Genesis side is
; perfoming a DMA ROM-to-VDP Transfer (setting RV=1)
; ----------------------------------------------------------------

Textur_Puyo:	binclude "data/mars/textures/testing_art.bin"
		align 4
Palette_Puyo:	binclude "data/mars/textures/testing_pal.bin"
		align 4
		
WAV_LEFT:	binclude "data/mars/rom/L.wav",$2C,$180000
WAV_LEFT_E:
		align 4
WAV_RIGHT:	binclude "data/mars/rom/R.wav",$2C,$180000
WAV_RIGHT_E:
		align 4
