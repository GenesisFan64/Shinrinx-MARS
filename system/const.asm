; ====================================================================
; ----------------------------------------------------------------
; Constants shared for both CPUs
; ----------------------------------------------------------------

MDRAM_START	equ $FFFF8800		; Start of working MD RAM (below it is free for CODE or decompression output)
MAX_MDERAM	equ $800		; MAX RAM for current screen mode (title,menu,or gameplay...)

; ====================================================================
; ----------------------------------------------------------------
; MD/MARS shared constants
; ----------------------------------------------------------------

; MD to MARS custom FIFO section
MAX_MDTSKARG	equ 8			; MAX MD task arguments
MAX_MDTASKS	equ 8			; MAX MD tasks

; model objects
		struct 0
mdl_data	ds.l 1			; Model data pointer, zero: model disabled
mdl_x_pos	ds.l 1			; X position $000000.00
mdl_y_pos	ds.l 1			; Y position $000000.00
mdl_z_pos	ds.l 1			; Z position $000000.00
mdl_x_rot	ds.l 1			; X rotation $000000.00
mdl_y_rot	ds.l 1			; Y rotation $000000.00
mdl_z_rot	ds.l 1			; Z rotation $000000.00
mdl_animdata	ds.l 1			; Model animation data pointer, zero: no animation
mdl_animframe	ds.l 1			; Current frame in animation
mdl_animtimer	ds.l 1			; Animation timer
mdl_animspd	ds.l 1			; Animation speed
sizeof_mdlobj	ds.l 0
		finish
		
; field view camera
		struct 0
cam_x_pos	ds.l 1			; X position $000000.00
cam_y_pos	ds.l 1			; Y position $000000.00
cam_z_pos	ds.l 1			; Z position $000000.00
cam_x_rot	ds.l 1			; X rotation $000000.00
cam_y_rot	ds.l 1			; Y rotation $000000.00
cam_z_rot	ds.l 1			; Z rotation $000000.00
cam_animdata	ds.l 1			; Model animation data pointer, zero: no animation
cam_animframe	ds.l 1			; Current frame in animation
cam_animtimer	ds.l 1			; Animation timer
cam_animspd	ds.l 1			; Animation speed
sizeof_camera	ds.l 0
		finish
		
		struct 0
mdllay_data	ds.l 1			; Model layout data, zero: Don't use layout
mdllay_x	ds.l 1			; X position
mdllay_y	ds.l 1			; Y position
mdllay_z	ds.l 1			; Z position
mdllay_x_last	ds.l 1			; LAST saved X position
mdllay_y_last	ds.l 1			; LAST saved Y position
mdllay_z_last	ds.l 1			; LAST saved Z position
mdllay_xr_last	ds.l 1			; LAST saved X rotation
sizeof_layout	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; MD Video
; ----------------------------------------------------------------

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

; call System_Input first, structure is below
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

varNullVram	equ $7FF		; Used in some Video routines

; ====================================================================
; ----------------------------------------------------------------
; Structures
; ----------------------------------------------------------------

; Controller buffer data (after calling System_Input)
		struct 0
pad_id		ds.b 1			; Controller ID
pad_ver		ds.b 1			; Controller type/revision: 0-3button 1-6button
on_hold		ds.w 1			; User HOLD bits
on_press	ds.w 1			; User PRESSED bits
sizeof_input	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; System RAM
; ----------------------------------------------------------------

		struct RAM_MdSystem
RAM_InputData	ds.b sizeof_input*4
RAM_SaveData	ds.b $200		; Save data cache (if using SRAM)
RAM_FifoToMars	ds.l MAX_MDTSKARG	; Data section to be sent to 32X
RAM_FrameCount	ds.l 1			; Framecount
RAM_SysRandVal	ds.l 1			; Random value
RAM_SysRandSeed	ds.l 1			; Randomness seed
RAM_initflug	ds.l 1			; "INIT" flag
RAM_SysFlags	ds.w 1			; Game engine flags (note: it's a byte)
RAM_MdMarsVInt	ds.w 3			; VBlank jump (JMP xxxx xxxx)
RAM_MdMarsHint	ds.w 3			; HBlank jump (JMP xxxx xxxx)
sizeof_mdsys	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; Sound 68k RAM
; ----------------------------------------------------------------

; This needs to be rewritten...
; it's very old

	; 68k side
	; Nothing here yet...
		struct RAM_MdSound
RAM_SoundNull	ds.l 1				; filler
sizeof_mdsnd	ds.l 0
		finish
		
	; Z80 side
	; TODO: remove this later
		struct $800
sndWavStart	ds.b 2			; Start address (inside or outside z80)
sndWavStartB	ds.b 1			; Start ROM bank * 8000h 
sndWavEnd	ds.b 2			; End address
sndWavEndB	ds.b 1			; End ROM bank *8000h
sndWavLoop	ds.b 2			; Loop address
sndWavLoopB	ds.b 1			; Loop ROM Bank * 8000h
sndWavPitch	ds.b 2			; pitch speed
sndWavFlags	ds.b 1			; playback flags
sndWavReq	ds.b 1			; request byte
		finish
		
; ====================================================================
; ----------------------------------------------------------------
; Video RAM
; ----------------------------------------------------------------

		struct RAM_MdVideo
RAM_VidPrntVram	ds.w 1		; Default VRAM location for ASCII text used by Video_Print
RAM_VidPrntList	ds.w 3*64	; Video_Print list: Address, Type
RAM_VdpRegs	ds.b 24		; VDP Register cache
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
	if MOMPASS=1				; First pass: empty sizes
RAM_ModeBuff	ds.l 0
RAM_MdSystem	ds.l 0
RAM_MdSound	ds.l 0
RAM_MdVideo	ds.l 0
RAM_ExRamSub	ds.l 0
RAM_MdGlobal	ds.l 0
sizeof_mdram	ds.l 0
	else
RAM_ModeBuff	ds.b MAX_MDERAM			; Second pass: sizes are set
RAM_MdSystem	ds.b sizeof_mdsys-RAM_MdSystem
RAM_MdSound	ds.b sizeof_mdsnd-RAM_MdSound
RAM_MdVideo	ds.b sizeof_mdvid-RAM_MdVideo
RAM_ExRamSub	ds.w $300			; (MANUAL SIZE) DMA routines that set RV=1
RAM_MdGlobal	ds.b sizeof_mdglbl-RAM_MdGlobal
sizeof_mdram	ds.l 0
	endif
	
	if MOMPASS=7
		message "MD RAM ends at: \{((sizeof_mdram)&$FFFFFF)}"
	endif
		finish
