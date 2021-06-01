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
; 68K RAMCODE Section, MUST BE ON RAM
; 
; MAX size: $8000
; ----------------------------------------------------------------

Engine_Code:
		phase $FF0000
; --------------------------------------------------------
; Include system features
; --------------------------------------------------------

		include	"system/md/sound.asm"
		include	"system/md/video.asm"
		include	"system/md/system.asm"
		
; --------------------------------------------------------
; Initialize system
; --------------------------------------------------------

		align 2
MD_Main:
		bsr 	Sound_init
		bsr 	Video_init
		bsr	System_Init
		include "code/gm_mode0.asm"
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
; DATA for DMA transfers, bank-free but
; Requires RV=1 to enabled
; --------------------------------------------------------

		align 4
		include "data/md_dma.asm"
		
; --------------------------------------------------------
; MARS data for SH2's ROM view
; This section will be gone if RV=1
; --------------------------------------------------------

		phase CS1+*
		align 4
		include "data/mars_rom.asm"
		dephase

; --------------------------------------------------------
; MD DATA BANK 0
; --------------------------------------------------------

		phase $900000+*				; Only one currently
		include "data/md_bank0.asm"
		dephase
		org $100000-4				; Add custom tag at the end.
		dc.b "BNK0"

; ; --------------------------------------------------------
; ; MD DATA BANK 1
; ; --------------------------------------------------------
; 
; 		phase $900000+*				; Only one currently
; 		include "data/md_bank1.asm"
; 		dephase
; 		org $200000-4				; Add custom tag at the end.
; 		dc.b "BNK1"

; ; --------------------------------------------------------
; ; MD DATA BANK 2
; ; --------------------------------------------------------
;
; 		phase $900000+*				; Only one currently
; 		include "data/md_bank2.asm"
; 		dephase
; 		org $300000-4				; Add custom tag at the end.
; 		dc.b "BNK2"

; ; --------------------------------------------------------
; ; MD DATA BANK 3
; ; --------------------------------------------------------
;
; 		phase $900000+*				; Only one currently
; 		include "data/md_bank3.asm"
; 		dephase
; 		org $400000-4				; Add custom tag at the end.
; 		dc.b "BNK3"

; ====================================================================
; ---------------------------------------------
; End
; ---------------------------------------------
		
ROM_END:
; 		rompad (ROM_END&$FF0000)+$40000
		align $8000
