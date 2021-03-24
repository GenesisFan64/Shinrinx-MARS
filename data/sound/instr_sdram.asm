; ====================================================================
; ----------------------------------------------------------------
; PWM Instruments
; Stored on 32X's SDRAM area
; but sample data is stored on the 32X's ROM view area
; ----------------------------------------------------------------

		align 4

; Example:		
; PwmIns_SPHEAVY1:
; 		dc.l PwmInsWav_SPHEAVY1		; Start
; 		dc.l PwmInsWav_SPHEAVY1_e	; End
; 		dc.l -1				; Sample loop point (-1: don't loop)
; 		dc.l %011			; Flags:
; 						; %SLR  S-stereo sample
; 						;      LR-enable output left/right
		
PwmIns_SPHEAVY1:
		dc.l PwmInsWav_SPHEAVY1
		dc.l PwmInsWav_SPHEAVY1_e
		dc.l -1
		dc.l %011
PwmIns_MCLSTRNG:
		dc.l PwmInsWav_MCLSTRNG
		dc.l PwmInsWav_MCLSTRNG_e
		dc.l -1
		dc.l %011
PwmIns_WHODSNARE:
		dc.l PwmInsWav_WHODSNARE
		dc.l PwmInsWav_WHODSNARE_e
		dc.l -1
		dc.l %011
PwmIns_TECHNOBASSD:
		dc.l PwmInsWav_TECHNOBASSD
		dc.l PwmInsWav_TECHNOBASSD_e
		dc.l -1
		dc.l %011
