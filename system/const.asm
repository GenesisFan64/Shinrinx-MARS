; ====================================================================
; ----------------------------------------------------------------
; 68000 RAM and constants
; ----------------------------------------------------------------

MDRAM_START	equ $FFFF8800	; Start of working RAM (below is free)
MAX_MDERAM	equ $800	; MAX RAM for Screen modes

; ====================================================================
; ----------------------------------------------------------------
; VDP Video
; ----------------------------------------------------------------

Vdp_palette	equ $C0000000		; Palette
Vdp_vsram	equ $40000010		; Vertical scroll

; ------------------------------------------------
; vdp_ctrl READ bits
; ------------------------------------------------

bitHint		equ 2
bitVint		equ 3
bitDma		equ 1

; ------------------------------------------------
; VDP register variables
; ------------------------------------------------

; Register $80
HVStop		equ $02
HintEnbl	equ $10
bitHVStop	equ 1
bitHintEnbl	equ 4

; Register $81
DispEnbl 	equ $40
VintEnbl 	equ $20
DmaEnbl		equ $10
bitDispEnbl	equ 6
bitVintEnbl	equ 5
bitDmaEnbl	equ 4
bitV30		equ 3

; ====================================================================
; --------------------------------------------------------
; Contoller reading (call System_Input first)
; --------------------------------------------------------

Controller_1	equ RAM_InputData
Controller_2	equ RAM_InputData+sizeof_input

; full WORD
JoyUp		equ $0001
JoyDown		equ $0002
JoyLeft		equ $0004
JoyRight	equ $0008
JoyB		equ $0010
JoyC		equ $0020
JoyA		equ $0040
JoyStart	equ $0080
JoyZ		equ $0100
JoyY		equ $0200
JoyX		equ $0400
JoyMode		equ $0800

; right byte $00xx
bitJoyUp	equ 0
bitJoyDown	equ 1
bitJoyLeft	equ 2
bitJoyRight	equ 3
bitJoyB		equ 4
bitJoyC		equ 5
bitJoyA		equ 6
bitJoyStart	equ 7

; left byte $xx00
bitJoyZ		equ 0
bitJoyY		equ 1
bitJoyX		equ 2
bitJoyMode	equ 3

; ====================================================================
; --------------------------------------------------------
; Others
; --------------------------------------------------------

RAM_VBlankGoTo	equ RAM_MdMarsVInt
RAM_HBlankGoTo	equ RAM_MdMarsHInt
varNullVram	equ $7FF		; Used in some Video routines

; ====================================================================
; ----------------------------------------------------------------
; Structures
; ----------------------------------------------------------------

; Controller
		struct 0
pad_id		ds.b 1
pad_ver		ds.b 1
on_hold		ds.w 1
on_press	ds.w 1
sizeof_input	ds.l 0
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
RAM_SoundNull	ds.l 1
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
; MD RAM
;
; NOTE: If using MCD Uses $FFFD00-$FFFDFF, and
; stack point is $FFFD00
; ----------------------------------------------------------------

		struct MDRAM_START
	if MOMPASS=1					; First pass, empty sizes
RAM_ModeBuff	ds.l 0
RAM_MdSystem	ds.l 0
RAM_MdSound	ds.l 0
RAM_MdVideo	ds.l 0
RAM_ExRamSub	ds.l 0
RAM_MdGlobal	ds.l 0
sizeof_mdram	ds.l 0
	else
RAM_ModeBuff	ds.b MAX_MDERAM				; Second pass, sizes are set
RAM_MdSystem	ds.b sizeof_mdsys-RAM_MdSystem
RAM_MdSound	ds.b sizeof_mdsnd-RAM_MdSound
RAM_MdVideo	ds.b sizeof_mdvid-RAM_MdVideo
RAM_ExRamSub	ds.w $300				; (MANUAL SIZE) routines for doing ROM-to-VDP DMA tasks
RAM_MdGlobal	ds.b sizeof_mdglbl-RAM_MdGlobal
sizeof_mdram	ds.l 0
	endif
	
	if MOMPASS=7
		message "MD RAM ends at: \{((sizeof_mdram)&$FFFFFF)}"
	endif
		finish
		
; ====================================================================
; ----------------------------------------------------------------
; MARS shared constants
; ----------------------------------------------------------------

; model objects
		struct 0
mdl_data	ds.l 1
mdl_anim 	ds.l 1
mdl_frame	ds.l 1
mdl_animcntr	ds.l 1			; Speed | Timer
mdl_x_pos	ds.l 1
mdl_y_pos	ds.l 1
mdl_z_pos	ds.l 1
mdl_x_rot	ds.l 1
mdl_y_rot	ds.l 1
mdl_z_rot	ds.l 1
sizeof_mdlobj	ds.l 0
		finish
		
; field view camera
		struct 0
cam_animdata	ds.l 1
cam_animframe	ds.l 1
cam_animtimer	ds.l 1
cam_animspd	ds.l 1
cam_x_pos	ds.l 1
cam_y_pos	ds.l 1
cam_z_pos	ds.l 1
cam_x_rot	ds.l 1
cam_y_rot	ds.l 1
cam_z_rot	ds.l 1
sizeof_camera	ds.l 0
		finish
