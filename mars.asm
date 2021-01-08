; ===========================================================================
; +-----------------------------------------------------------------+
; 32X GAME BASE
; 
; Started on 16/01/2020
; +-----------------------------------------------------------------+

		include	"system/macros.asm"	; Assembler macros
		include	"system/const.asm"	; MD and MARS Variables are located here
		include	"system/md/map.asm"	; Genesis hardware map
		include	"system/mars/map.asm"	; MARS map
		
; ====================================================================
; ----------------------------------------------------------------
; Header
; ----------------------------------------------------------------

		include	"system/head.asm"	; Header, contains 32X specific setup

; ====================================================================
; ----------------------------------------------------------------
; 68K CODE Section
; 
; Stored on RAM to prevent BUS fighting (Kolibri-style)
; 
; or if needed: remove the RAM-copying part from head.asm and
; change the phase from $FF0000 to $880000 (Size: 512kb)
; ----------------------------------------------------------------

Engine_Code:
		phase $FF0000
		include "code/md.asm"
		dephase
Engine_Code_end:
	if MOMPASS=7
		message "MD CODE uses: \{Engine_Code_end-Engine_Code}"
	endif
	
; ====================================================================
; ----------------------------------------------------------------
; SH2 CODE for 32X
; ----------------------------------------------------------------

		align 4
MARS_RAMDATA:
		include "code/mars.asm"
		ltorg
		cpu 68000
		padding off
		dephase
MARS_RAMDATA_E:
		align 4

; ====================================================================
; MD DATA BANK
; 
; $900000 - $9FFFFF
; ====================================================================

		align 4
		phase $900000+*				; Only one currently
		include "data/md_bank0.asm"
		dephase

; ====================================================================
; DATA for DMA transfers (bank-less but with the old limitations)
; ====================================================================

		align 4
		include "data/md_dmadata0.asm"
		
; ====================================================================
; MARS ROM data (Acessed by SH2 only)
; 
; This will be gone if doing DMA transfers
; ====================================================================

		phase CS1+*
		align 4
		include "data/mars_rom.asm"
		dephase

; ====================================================================
; ---------------------------------------------
; End
; ---------------------------------------------
		
ROM_END:
; 		rompad (ROM_END&$FF0000)+$40000
		align $8000
