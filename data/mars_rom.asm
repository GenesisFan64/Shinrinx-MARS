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

; --------------------------------------------------------
; Maps
; --------------------------------------------------------

		align $8000
		include  "data/mars/incl_rom.asm"	; All textures will go in ROM

; PWM_STEREO:	binclude "data/sound/pwm_st.wav",$2C,$200000
; PWM_STEREO_e:
		align 4
PwmInsWav_SPHEAVY1:
		binclude "data/sound/instr/smpl/SPHEAVY1.wav",$2C
PwmInsWav_SPHEAVY1_e:
		align 4
PwmInsWav_MCLSTRNG:
		binclude "data/sound/instr/smpl/MCLSTRNG.wav",$2C
PwmInsWav_MCLSTRNG_e:
		align 4
PwmInsWav_WHODSNARE:
		binclude "data/sound/instr/smpl/ST-79_whodini-snare.wav",$2C
PwmInsWav_WHODSNARE_e:
		align 4
PwmInsWav_TECHNOBASSD:
		binclude "data/sound/instr/smpl/ST-72_techno-bassd3.wav",$2C
PwmInsWav_TECHNOBASSD_e:
		align 4
