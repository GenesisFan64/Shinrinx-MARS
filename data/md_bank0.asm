; ====================================================================
; ----------------------------------------------------------------
; Single 68k DATA BANK for MD ($900000-$9FFFFF)
; for stuff other than MD's DMA data
; 
; Maximum size: $0FFFFF bytes per bank
; ----------------------------------------------------------------

		align $8000
		include "data/sound/tracks.asm"
		align 4
; CAMERA_INTRO:	binclude "data/mars/objects/anim/intro_anim.bin"
; 		align 4
PWM_START:	binclude "data/sound/pwm_m.wav",$2C,$08FFFF
PWM_END:
