; ====================================================================
; ----------------------------------------------------------------
; MD RAM
;
; NOTE:
; MCD Uses $FFFD00-$FFFDFF, stack starts at $FFFD00
; ----------------------------------------------------------------

		struct MDRAM_START
	if MOMPASS=1				; First pass, empty sizes
RAM_ModeBuff	ds.l 0
RAM_MdSystem	ds.l 0
RAM_MdSound	ds.l 0
RAM_MdVideo	ds.l 0
RAM_ExRamSub	ds.l 0
RAM_MdGlobal	ds.l 0
sizeof_mdram	ds.l 0
	else
RAM_ModeBuff	ds.b MAX_MDERAM			; Second pass, sizes are set
RAM_MdSystem	ds.b sizeof_mdsys-RAM_MdSystem
RAM_MdSound	ds.b sizeof_mdsnd-RAM_MdSound
RAM_MdVideo	ds.b sizeof_mdvid-RAM_MdVideo
RAM_ExRamSub	ds.w $500			; ROM-to-VDP DMA routines
RAM_MdGlobal	ds.b sizeof_mdglbl-RAM_MdGlobal
sizeof_mdram	ds.l 0
	endif
	
	if MOMPASS=7
		message "MD RAM ends at: \{((sizeof_mdram)&$FFFFFF)}"
	endif
		finish

; ====================================================================
; ----------------------------------------------------------------
; System RAM
; ----------------------------------------------------------------

		struct RAM_MdSystem
RAM_InputData	ds.b sizeof_input*4
RAM_SaveData	ds.b $200		; Save data cache (if using SRAM)
RAM_FrameCount	ds.l 1
RAM_SysRandVal	ds.l 1
RAM_SysRandSeed	ds.l 1
RAM_initflug	ds.l 1			; "INIT"
RAM_GameMode	ds.w 1			; Master game mode
RAM_SysFlags	ds.w 1			; (byte)
RAM_MdMarsVInt	ds.w 3			; JMP xxxx xxxx
RAM_MdMarsHint	ds.w 3			; JMP xxxx xxxx
sizeof_mdsys	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; Sound 68k RAM
; ----------------------------------------------------------------

	; 68k side
		struct RAM_MdSound
RAM_SoundTemp	ds.l 1
sizeof_mdsnd	ds.l 0
		finish
		
	; Z80 side
		struct $800
sndWavStart	ds.b 2		; Start address (inside or outside z80)
sndWavStartB	ds.b 1		; Start ROM bank * 8000h 
sndWavEnd	ds.b 2		; End address
sndWavEndB	ds.b 1		; End ROM bank *8000h
sndWavLoop	ds.b 2		; Loop address
sndWavLoopB	ds.b 1		; Loop ROM Bank * 8000h
sndWavPitch	ds.b 2		; pitch speed
sndWavFlags	ds.b 1		; playback flags
sndWavReq	ds.b 1		; request byte
		finish
		
; ====================================================================
; ----------------------------------------------------------------
; Video RAM
; ----------------------------------------------------------------

		struct RAM_MdVideo
RAM_VidPrntVram	ds.w 1
RAM_VidPrntList	ds.w 3*64		; vdp addr (LONG), type (WORD)
RAM_VdpRegs	ds.b 24
sizeof_mdvid	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; MARS SH2 RAM
; ----------------------------------------------------------------

SH2_RAM:
		struct SH2_RAM|TH
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
