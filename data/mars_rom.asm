; ====================================================================
; ----------------------------------------------------------------
; SH2 ROM user data
; 
; If your data is too much for SDRAM, place it here.
; Note that this section will be gone if the Genesis side is
; perfoming a DMA ROM-to-VDP Transfer (setting RV=1)
; 
; also, reading from here is slow (supposedly)
; ----------------------------------------------------------------

		align 4
Textr_marscity:
		binclude "data/mars/models/mtrl/marscity_art.bin"
		align 4
		
; WAV_LEFT:	binclude "data/mars/L.wav",$2C,$100000
; WAV_LEFT_E:
; 		align 4
; WAV_RIGHT:	binclude "data/mars/R.wav",$2C,$100000
; WAV_RIGHT_E:
; 		align 4
