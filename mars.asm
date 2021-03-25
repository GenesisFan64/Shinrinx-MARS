; ===========================================================================
; +-----------------------------------------------------------------+
; PROJECT SHINRINX
; 
; Started on 16/01/2020
; +-----------------------------------------------------------------+

		include	"system/macros.asm"	; Assembler macros
		include	"system/md/const.asm"	; MD and MARS Variables
		include	"system/md/map.asm"	; Genesis hardware map
		include	"system/mars/map.asm"	; MARS map
		
; ====================================================================
; ----------------------------------------------------------------
; Header
; ----------------------------------------------------------------

		include	"system/head.asm"	; 32X Header and boot sequence

; ====================================================================
; ----------------------------------------------------------------
; 68K RAMCODE Section
; Stored on RAM to prevent BUS fighting (Kolibri-style)
; 
; MAX size: $8000
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
		align 2
	if MOMPASS=6
		message "MD RAM CODE uses: \{Engine_Code_end-Engine_Code}"
	endif
	
; ====================================================================
; ----------------------------------------------------------------
; SH2 CODE for 32X
; ----------------------------------------------------------------

		align 4
MARS_RAMDATA:
		include "system/mars/code.asm"
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
		include "data/md_dma.asm"
		
; --------------------------------------------------------
; MARS ROM data seen on SH2
; 
; This section will be gone if RV=1
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
