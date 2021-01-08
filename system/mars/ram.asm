; ====================================================================
; ----------------------------------------------------------------
; MARS SH2 RAM
; ----------------------------------------------------------------

; ====================================================================
; ----------------------------------------------------------------
; MARS System RAM
; ----------------------------------------------------------------

		struct MarsRam_System
MarsSys_Input	ds.l 4
MARSSys_MdReq	ds.l 1
sizeof_marssys	ds.l 0
		finish
		
; ====================================================================
; ----------------------------------------------------------------
; MARS Sound RAM
; ----------------------------------------------------------------

		struct MarsRam_Sound
MARSSnd_Pwm	ds.b sizeof_sndchn*8
sizeof_marssnd	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; MARS Video RAM
; ----------------------------------------------------------------

		struct MarsRam_Video
MARSVid_LastFb	ds.l 1
MarsVid_VIntBit	ds.l 1
MARSMdl_FaceCnt	ds.l 1
MarsMdl_CurrPly	ds.l 2
MarsMdl_CurrZtp	ds.l 1
MarsMdl_CurrZds	ds.l 1
MarsPly_ZList	ds.l 2*MAX_POLYGONS			; Polygon address | Polygon Z pos
MARSVid_Palette	ds.w 256
MARSMdl_Playfld	ds.b sizeof_plyfld			; Playfield buffer (or camera)
MARSVid_Polygns	ds.b sizeof_polygn*MAX_POLYGONS		; Polygon data
MARSMdl_Objects	ds.b sizeof_mdl*MAX_MODELS
sizeof_marsvid	ds.l 0
		finish
	
; ====================================================================
; ----------------------------------------------------------------
; MARS Sound RAM
; ----------------------------------------------------------------

		struct SH2_CODE_END|TH
	if MOMPASS=1
MarsRam_System	ds.l 0
MarsRam_Video	ds.l 0
MarsRam_Sound	ds.l 0
sizeof_marsram	ds.l 0
	else
MarsRam_System	ds.b (sizeof_marssys-MarsRam_System)
MarsRam_Video	ds.b (sizeof_marsvid-MarsRam_Video)
MarsRam_Sound	ds.b (sizeof_marssnd-MarsRam_Sound)
sizeof_marsram	ds.l 0
	endif

.here:
	if MOMPASS=7
		message "MARS RAM from \{((SH2_RAM)&$FFFFFF)} to \{((.here)&$FFFFFF)}"
	endif
		finish
