; ====================================================================
; ----------------------------------------------------------------
; PWM Instrument pointers stored on 32X's SDRAM area
; the sample data is stored on the 32X's ROM view area
; (data/mars_rom.asm)
; ----------------------------------------------------------------

; Example:		
; PwmIns_SPHEAVY1:
; 		dc.l PwmInsWav_SPHEAVY1		; Start
; 		dc.l PwmInsWav_SPHEAVY1_e	; End
; 		dc.l -1				; Sample loop point (-1: don't loop)
; 		dc.l %011			; Flags:
; 						; %S0000000 S-stereo sample
; 						; 

		align 4		
; PwmIns_SPHEAVY1:
; 		dc.l PwmInsWav_SPHEAVY1
; 		dc.l PwmInsWav_SPHEAVY1_e
; 		dc.l -1
; 		dc.l 0
; PwmIns_MCLSTRNG:
; 		dc.l PwmInsWav_MCLSTRNG
; 		dc.l PwmInsWav_MCLSTRNG_e
; 		dc.l -1
; 		dc.l 0
; PwmIns_WHODSNARE:
; 		dc.l PwmInsWav_WHODSNARE
; 		dc.l PwmInsWav_WHODSNARE_e
; 		dc.l -1
; 		dc.l 0
; PwmIns_TECHNOBASSD:
; 		dc.l PwmInsWav_TECHNOBASSD
; 		dc.l PwmInsWav_TECHNOBASSD_e
; 		dc.l -1
; 		dc.l 0
PwmIns_String:
		dc.l PwmInsWav_String
		dc.l PwmInsWav_String_e
		dc.l 0
		dc.l 0
PwmIns_Piano:
		dc.l PwmInsWav_Piano
		dc.l PwmInsWav_Piano_e
		dc.l -1
		dc.l 0
