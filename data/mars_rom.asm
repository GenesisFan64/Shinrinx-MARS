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
; PWM_LEFT:	binclude "data/sound/pwm_l.wav",$2C,$140000
; PWM_LEFT_e:
; 		align 4
; PWM_MONO:	binclude "data/sound/pwm_mono.wav",$2C,$120000
; PWM_MONO_e:
; 		align 4
PWM_STEREO:	binclude "data/sound/pwm_st.wav",$2C,$200000
PWM_STEREO_e:
		align 4
