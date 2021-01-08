; ===========================================================================
; ----------------------------------------------------------------
; MACROS
; ----------------------------------------------------------------

; --------------------------------------------------------
; AS Main settings
; --------------------------------------------------------

		!org 0				; Start at 0
		cpu 		68000		; BASE CPU is 68k (manually changed later)
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
mapsize		function l,r,( ((l-1)/8)<<16&$FFFF0000|((r-1)/8)&$FFFF ); for cell w/h use doubleword
locate		function a,b,c,(c&$FF)|(b<<8&$FF00)|(a<<16&$FF0000)	; VDP locate: Layer|X pos|Y pos for some video routines

; ====================================================================
; ---------------------------------------------
; Macros
; ---------------------------------------------

; -------------------------------------
; Reserve memory space
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

; ; -------------------------------------
; ; ZERO Fill padding
; ; -------------------------------------
; 
; rompad		macro address			; Zero fill
; diff := address - *
; 		if diff < 0
; 			error "too much stuff before org $\{address} ($\{(-diff)} bytes)"
; 		else
; 			while diff > 1024
; 				; AS can only generate 1 kb of code on a single line
; 				dc.b [1024]0
; diff := diff - 1024
; 			endm
; 			dc.b [diff]0
; 		endif
; 	endm
	
; -------------------------------------
; ORG
;
; (taken from s2disasm)
; -------------------------------------

; paddingSoFar set 0
; ; 128 = 80h = z80, 32988 = 80DCh = z80unDoC 
; notZ80 function cpu,(cpu<>128)&&(cpu<>32988)
; 
; ; make org safer (impossible to overwrite previously assembled bytes) and count padding
; ; and also make it work in Z80 code without creating a new segment
; org macro address
; 	if notZ80(MOMCPU)
; 		if address < *
; 			error "too much stuff before org $\{address} ($\{(*-address)} bytes)"
; 		elseif address > *
; paddingSoFar	set paddingSoFar + address - *
; 			!org address
; 		endif
; 	else
; 		if address < $
; 			error "too much stuff before org 0\{address}h (0\{($-address)}h bytes)"
; 		else
; 			while address > $
; 				db 0
; 			endm
; 		endif
; 	endif
;     endm
