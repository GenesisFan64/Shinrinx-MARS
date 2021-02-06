; ===========================================================================
; +-----------------------------------------------------------------+
; PROJECT SHINRINX
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
; ----------------------------------------------------------------

Engine_Code:
		phase $FF0000
; --------------------------------------------------------
; Include system features
; --------------------------------------------------------

		include	"system/md/system.asm"
		include	"system/md/video.asm"
		include	"system/md/sound.asm"
		
; --------------------------------------------------------
; Initialize system
; --------------------------------------------------------

MD_Main:
		bsr 	Sound_init
		bsr 	Video_init
		bsr	System_Init
		include "code/md/gm_mode0.asm"
		dephase
Engine_Code_end:
	if MOMPASS=6
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

; --------------------------------------------------------
; SINGLE MD BANK
; 
; $900000 - $9FFFFF
; --------------------------------------------------------

		align 4
		phase $900000+*				; Only one currently
		include "data/md_bank0.asm"
		dephase

; --------------------------------------------------------
; DATA for DMA transfers, bank-less
; --------------------------------------------------------

		align 4
		include "data/md_dmadata0.asm"
		
; --------------------------------------------------------
; MARS ROM data for SH2
; 
; This section will be gone if RV=1
; (doing any MD ROM-to-DMA transfer)
; --------------------------------------------------------

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
