; ====================================================================
; ----------------------------------------------------------------
; Single 68k DATA BANK for MD ($900000-$9FFFFF)
; for stuff other than DMA transfers
; 
; Maximum size: $0FFFFF bytes
; ----------------------------------------------------------------

		align $8000
		include "data/sound/tracks.asm"

		align 4
CAMERA_INTRO:	binclude "data/mars/objects/anim/intro_anim.bin"
		align 4
; TEST_WAV:	binclude "data/sound/test.wav",$2C,$CFFFF
; TEST_WAV_e:
