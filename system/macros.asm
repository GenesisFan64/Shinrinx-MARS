; ===========================================================================
; ----------------------------------------------------------------
; MACROS
; ----------------------------------------------------------------

; --------------------------------------------------------
; AS Main settings
; --------------------------------------------------------

		!org 0				; Start at 0
		cpu 		68000		; Current CPU is 68k, gets changed later
		padding		off		; Dont pad dc.b
		listing 	purecode	; Want listing file, but only the final code in expanded macros
		supmode 	on 		; Supervisor mode
		dottedstructs	off		; If needed
		page 		0

; ====================================================================
; ---------------------------------------------
; Functions
; ---------------------------------------------

doubleword 	function l,r,(l<<16&$FFFF0000|r&$FFFF)			; LLLL RRRR
mapsize		function l,r,(((l-1)/8)<<16&$FFFF0000|((r-1)/8)&$FFFF)	; for cells w/h use doubleword
locate		function a,b,c,(c&$FF)|(b<<8&$FF00)|(a<<16&$FF0000)	; VDP locate: Layer|X pos|Y pos for some video routines

; ====================================================================
; ---------------------------------------------
; Macros
; ---------------------------------------------

; -------------------------------------
; Reserve memory section
; -------------------------------------

struct		macro thisinput			; Reserve memory address
GLBL_LASTPC	set *
		dephase
GLBL_LASTORG	set *
		phase thisinput
		endm
		
; -------------------------------------
; Finish
; -------------------------------------

finish		macro				; Then finish custom struct.
		!org GLBL_LASTORG
		phase GLBL_LASTPC
		endm
