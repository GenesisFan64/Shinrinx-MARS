; ====================================================================
; ----------------------------------------------------------------
; ROM HEADER FOR 32X
; 
; These labels work even if the 32X isn't present
; ----------------------------------------------------------------

		dc.l 0				; Stack point
		dc.l $3F0			; Entry point (always $3F0)
		dc.l MD_ErrBus			; Bus error
		dc.l MD_ErrAddr			; Address error
		dc.l MD_ErrIll			; ILLEGAL Instruction
		dc.l MD_ErrZDiv			; Divide by 0
		dc.l MD_ErrChk			; CHK Instruction
		dc.l MD_ErrTrapV		; TRAPV Instruction
		dc.l MD_ErrPrivl		; Privilege violation
		dc.l MD_Trace			; Trace
		dc.l MD_Line1010		; Line 1010 Emulator
		dc.l MD_Line1111		; Line 1111 Emulator
		dc.l MD_ErrorEx			; Error exception
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx	
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx		
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l RAM_HBlankGoTo		; RAM jump for HBlank (JMP xxxx xxxx)
		dc.l MD_ErrorTrap
		dc.l RAM_VBlankGoTo		; RAM jump for VBlank (JMP xxxx xxxx)
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.b "SEGA 32X        "
		dc.b "(C)GF64 2021.???"
		dc.b "Proyecto Chirinx                                "
		dc.b "Project Shinrinx                                "
		dc.b "GM HOMEBREW-00"
		dc.w 0
		dc.b "J6              "
		dc.l 0
		dc.l ROM_END
		dc.l $FF0000
		dc.l $FFFFFF
		dc.l $20202020		; dc.b "RA",$F8,$20
		dc.l $20202020		; $200000
		dc.l $20202020		; $203FFF
		align $1F0
		dc.b "U               "

; ====================================================================
; ----------------------------------------------------------------
; Second header for 32X
; 
; These new jumps are for the 68K if the 32X is currently
; active.
; ----------------------------------------------------------------

		jmp	($880000|MARS_Entry).l
		jmp	($880000|MD_ErrBus).l			; Bus error
		jmp	($880000|MD_ErrAddr).l			; Address error
		jmp	($880000|MD_ErrIll).l			; ILLEGAL Instruction
		jmp	($880000|MD_ErrZDiv).l			; Divide by 0
		jmp	($880000|MD_ErrChk).l			; CHK Instruction
		jmp	($880000|MD_ErrTrapV).l			; TRAPV Instruction
		jmp	($880000|MD_ErrPrivl).l			; Privilege violation
		jmp	($880000|MD_Trace).l			; Trace
		jmp	($880000|MD_Line1010).l			; Line 1010 Emulator
		jmp	($880000|MD_Line1111).l			; Line 1111 Emulator
		jmp	($880000|MD_ErrorEx).l			; Error exception
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l	
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l		
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	(RAM_HBlankGoTo).l			; RAM jump for HBlank (JMP xxxx xxxx)
		jmp	($880000|MD_ErrorTrap).l
		jmp	(RAM_VBlankGoTo).l			; RAM jump for VBlank (JMP xxxx xxxx)
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l

; ----------------------------------------------------------------

		align $3C0
		dc.b "MARS CHECK MODE "			; Module name
		dc.l 0					; Version (always 0)
		dc.l MARS_RAMDATA			; Set to 0 if SH2 code points to ROM
		dc.l 0					; No info, set to zero.
		dc.l MARS_RAMDATA_e-MARS_RAMDATA	; Set to 4 if SH2 code points to ROM
		dc.l SH2_M_Entry			; Master SH2 PC
		dc.l SH2_S_Entry			; Slave SH2 PC
		dc.l SH2_Master				; Master SH2 default VBR
		dc.l SH2_Slave				; Slave SH2 default VBR
		binclude "system/mars/data/security.bin"

; ====================================================================
; ----------------------------------------------------------------
; Entry point
; 
; must be at $3F0
; ----------------------------------------------------------------

MARS_Entry:
		bcs	.no_mars		; if carry set, 32X is not present
		move.l	#0,(RAM_initflug).l
		btst	#15,d0
		beq.s	.init
		lea	(sysmars_reg).l,a5
		btst.b	#0,adapter(a5)		; Adapter enable
		bne	.adapterenable
		move.l	#0,comm8(a5)
		lea	.ramcode(pc),a0		; copy from ROM to WRAM
		lea	($FF0000).l,a1
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		lea	($FF0000).l,a0
		jmp	(a0)			; jump workram
.ramcode:
		move.b	#1,adapter(a5)		; MARS mode
		lea	.restarticd(pc),a0
		adda.l	#$880000,a0
		jmp	(a0)
.restarticd:
		lea	($A10000).l,a5
		move.l	#-64,a4
		move.w	#3900,d7
		lea	($880000+$6E4),a1
		jmp	(a1)
.adapterenable:
		lea	(sysmars_reg),a5
		btst.b	#1,adapter(a5)		; SH2 Reset
		bne.s	.hotstart
		bra.s	.restarticd

; ------------------------------------------------
; Init
; ------------------------------------------------

.init:
		move.w	#$2700,sr
		lea	(sysmars_reg).l,a5
		move.l	#"68UP",comm12(a5)			; Report to both SH2 we are done here
.wm:		cmp.l	#"M_OK",comm0(a5)			; SH2 Master OK ?
		bne.s	.wm
.ws:		cmp.l	#"S_OK",comm4(a5)			; SH2 Slave OK ?
		bne.s	.ws
		moveq	#0,d0					; Reset comm values
		move.l	d0,comm0(a5)
		move.l	d0,comm4(a5)
		move.l	d0,comm12(a5)
		move.l	#"INIT",(RAM_initflug).l		; Set "INIT" as our boot flag
.hotstart:
		cmp.l	#"INIT",(RAM_initflug).l		; Did it write?
		bne.s	.init					; Restart everything and try again.
		bsr	MD_Init					; Minimal initialization
		lea	Engine_Code(pc),a0			; Copy ALL our 68k code to RAM,
		lea	($FF0000),a1				; we can use $880000 but there will be BUS fighting
		move.w	#Engine_Code_end-Engine_Code/2,d0	; on every instruction (according to 32X.FAQ)
.copyme:
		move.w	(a0)+,(a1)+
		dbf	d0,.copyme
		jmp	(MD_Main).l				; $FF0000 + MD_Main

; ====================================================================
; ----------------------------------------------------------------
; If 32X is not detected
; ----------------------------------------------------------------

.no_mars:
		move.w	#$2700,sr				; Disable interrupts
		move.l	#$C0000000,(vdp_ctrl).l			; Blue screen
		move.w	#$0E00,(vdp_data).l
		bra.s	*
		
; ====================================================================
; ----------------------------------------------------------------
; Init MD
; ----------------------------------------------------------------

MD_Init:
		moveq	#0,d0
		movea.l	d0,a6
		move.l	a6,usp
.waitframe:	move.w	(vdp_ctrl).l,d0		; Wait 1 frame
		btst	#bitVint,d0
		beq.s	.waitframe
		move.l	#$80048144,(vdp_ctrl).l	; Keep display
		lea	($FFFF0000),a0		; Clean all RAM before $FFF000
		move.w	#($F000/4)-1,d0
.clrram:
		clr.l	(a0)+
		dbf	d0,.clrram
		movem.l	($FF0000),d0-a6		; Clear registers (using 10 LONG zeros from already clean RAM)
		rts

; ====================================================================
; ----------------------------------------------------------------
; Error traps
; ----------------------------------------------------------------

MD_ErrBus:		; Bus error
MD_ErrAddr:		; Address error
MD_ErrIll:		; ILLEGAL Instruction
MD_ErrZDiv:		; Divide by 0
MD_ErrChk:		; CHK Instruction
MD_ErrTrapV:		; TRAPV Instruction
MD_ErrPrivl:		; Privilege violation
MD_Trace:		; Trace
MD_Line1010:		; Line 1010 Emulator
MD_Line1111:		; Line 1111 Emulator
MD_ErrorEx:		; Error exception
MD_ErrorTrap:
		rte
