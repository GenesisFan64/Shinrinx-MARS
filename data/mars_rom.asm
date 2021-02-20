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

		include  "data/mars/objects/incl_rom.asm"	; All textures will go in ROM
PWM_LEFT:	binclude "data/sound/pwm_l.wav",$2C,$140000
PWM_LEFT_e:
		align 4
PWM_RIGHT:	binclude "data/sound/pwm_r.wav",$2C,$140000
PWM_RIGHT_e:
		align 4
