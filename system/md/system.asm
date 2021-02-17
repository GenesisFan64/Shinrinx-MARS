; ====================================================================
; ----------------------------------------------------------------
; System
; ----------------------------------------------------------------

; --------------------------------------------------------
; Init System
; 
; Uses:
; a0-a2,d0-d1
; --------------------------------------------------------

System_Init:
		move.w	#$2700,sr		; Disable interrupts
		move.w	#$0100,(z80_bus).l	; Stop Z80
.wait:
		btst	#0,(z80_bus).l		; Wait for it
		bne.s	.wait
		moveq	#%01000000,d0		; Init ports, TH=1
		move.b	d0,(sys_ctrl_1).l	; Controller 1
		move.b	d0,(sys_ctrl_2).l	; Controller 2
		move.b	d0,(sys_ctrl_3).l	; Modem
		move.w	#0,(z80_bus).l		; Enable Z80
		lea	(RAM_InputData),a0	; Clear input data buffer
		move.w	#sizeof_input-1/2,d1
		moveq	#0,d0
.clrinput:
		move.w	#0,(a0)+
		dbf	d1,.clrinput
		move.w	#$4EF9,d0		; Set JMP opcode for the Hblank/VBlank jumps
 		move.w	d0,(RAM_MdMarsVInt).l
		move.w	d0,(RAM_MdMarsHInt).l
		move.l	#$56255769,d0		; Set these random values
		move.l	#$95116102,d1
		move.l	d0,(RAM_SysRandVal).l
		move.l	d1,(RAM_SysRandSeed).l
		move.l	#VInt_Default,d0	; Set default ints
		move.l	#Hint_Default,d1
		bsr	System_SetInts
		move.w	#$2000,sr		; Enable interrupts
		rts
; 		bra	System_SaveInit

; ====================================================================
; --------------------------------------------------------
; System_Input (VBLANK ONLY)
; 
; Uses:
; d4-d6,a4-a5
; --------------------------------------------------------

; TODO: check if it still required to turn OFF the Z80
; while reading input... It works fine on hardware though.

System_Input:
; 		move.w	#$0100,(z80_bus).l	; Stop Z80
.wait:
; 		btst	#0,(z80_bus).l		; Wait for it
; 		bne.s	.wait
		lea	($A10003),a4
		lea	(RAM_InputData),a5
		bsr.s	.this_one
		adda	#2,a4
		adda	#sizeof_input,a5
; 		bsr.s	.this_one
; 		move.w	#0,(z80_bus).l
; 		rts

; --------------------------------------------------------	
; Read port
; 
; a4 - Current port
; a5 - Output data
; --------------------------------------------------------

.this_one:
		bsr	.pick_id
		move.b	d4,pad_id(a5)
		cmp.w	#$F,d4
		beq.s	.exit
		and.w	#$F,d4
		add.w	d4,d4
		move.w	.list(pc,d4.w),d5
		jmp	.list(pc,d5.w)
.exit:
		clr.b	pad_ver(a5)
		rts

; --------------------------------------------------------
; Grab ID
; --------------------------------------------------------

.list:		dc.w .exit-.list	; $0
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list	; $4
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list	; $8
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list	; $C
		dc.w .id_0D-.list
		dc.w .exit-.list
		dc.w .exit-.list

; --------------------------------------------------------
; ID $0D
; 
; Normal controller, Old or New
; --------------------------------------------------------

.id_0D:
		move.b	#$40,(a4)	; Show CB|RLDU
		nop
		nop
		move.b	#$00,(a4)	; Show SA|RLDU
		nop
		nop
		move.b	#$40,(a4)	; Show CB|RLDU
		nop
		nop
		move.b	#$00,(a4)	; Show SA|RLDU
		nop
		nop
		move.b	#$40,(a4)	; 6 button responds
		nop
		nop
		move.b	(a4),d4		; Grab ??|MXYZ
 		move.b	#$00,(a4)
  		nop
  		nop
 		move.b	(a4),d6		; Type: $03 old, $0F new
 		move.b	#$40,(a4)
 		nop
 		nop
		and.w	#$F,d6
		lsr.w	#2,d6
		and.w	#1,d6
		beq.s	.oldpad
		not.b	d4
 		and.w	#%1111,d4
		move.b	on_hold(a5),d5
		eor.b	d4,d5
		move.b	d4,on_hold(a5)
		and.b	d4,d5
		move.b	d5,on_press(a5)
.oldpad:
		move.b	d6,pad_ver(a5)
		
		move.b	#$00,(a4)	; Show SA??|RLDU
		nop
		nop
		move.b	(a4),d4
		lsl.b	#2,d4
		and.b	#%11000000,d4
		move.b	#$40,(a4)	; Show ??CB|RLDU
		nop
		nop
		move.b	(a4),d5
		and.b	#%00111111,d5
		or.b	d5,d4
		not.b	d4
		move.b	on_hold+1(a5),d5
		eor.b	d4,d5
		move.b	d4,on_hold+1(a5)
		and.b	d4,d5
		move.b	d5,on_press+1(a5)
		rts
		
; --------------------------------------------------------
; Grab ID
; --------------------------------------------------------

.pick_id:
		moveq	#0,d4
		move.b	#%01110000,(a4)		; TH=1,TR=1,TL=1
		nop
		nop
		bsr.s	.get_id
		move.b	#%00110000,(a4)		; TH=0,TR=1,TL=1
		nop
		nop
		add.w	d4,d4
.get_id:
		move.b	(a4),d5
		move.b	d5,d6
		and.b	#$C,d6
		beq.s	.step_1
		addq.w	#1,d4
.step_1:
		add.w	d4,d4
		move.b	d5,d6
		and.w	#3,d6
		beq.s	.step_2
		addq.w	#1,d4
.step_2:
		rts
		
; 		moveq	#0,d0
; 		bsr.s	System_ReadPad
; 		lea	(RAM_Control+(16*4)),a5
; 		moveq	#1,d0
; 		bsr.s	System_ReadPad
; 		
; 		lea	($A10003).l,a6
; 		lsl.w	#1,d0
; 		add.w	d0,a6		; Add result to port
; 		bsr.s	.srch_pad
; 		move.b	d0,(a5)
; 		move.w	#0,(z80_bus).l
; 		rts

; --------------------------------------------------------
; System_Random
; 
; Set random value
; 
; Output:
; d0 | LONG
; --------------------------------------------------------

System_Random:
		move.l	(RAM_SysRandSeed),d5
		move.l	(RAM_SysRandVal),d4
		rol.l	#1,d5
		asr.l	#1,d4
		add.l	d5,d4
		move.l	d5,(RAM_SysRandSeed).l
		move.l	d4,(RAM_SysRandVal).l
		move.l	d4,d0
		rts
		
; --------------------------------------------------------
; System_SetInts
; 
; Set new interrputs
; 
; d0 | LONG - VBlank
; d1 | LONG - HBlank
;
; Uses:
; d4
; 
; Notes:
; setting 0 or negative number will ignore changes
; --------------------------------------------------------

System_SetInts:
		move.l	d0,d4
		beq.s	.novint
		bmi.s	.novint
		or.l	#$880000,d4
 		move.l	d4,(RAM_MdMarsVInt+2).l
.novint:
		move.l	d1,d4
		beq.s	.nohint
		bmi.s	.nohint
		or.l	#$880000,d4
		move.l	d4,(RAM_MdMarsHInt+2).l
.nohint:
		rts

; --------------------------------------------------------
; System_SaveInit
; 
; Init save data
; 
; Uses:
; a4,d4-d5
; --------------------------------------------------------

; TODO: Check if RV bit is required here...
System_SaveInit:
		move.b	#1,(md_bank_sram).l
		lea	($200001).l,a4
		moveq	#0,d4
		move.w	#($4000/2)-1,d5
.initsave:
		move.b	d4,(a4)
		adda	#2,a4
		dbf	d5,.initsave
		move.b	#0,(md_bank_sram).l
		rts

; --------------------------------------------------------
; System_VSync
; 
; Waits for VBlank manually
; 
; Uses:
; d4
; --------------------------------------------------------

System_VSync:
		move.w	(vdp_ctrl),d4
		btst	#bitVint,d4
		beq.s	System_VSync
		bsr	System_Input
		add.l	#1,(RAM_FrameCount).l
.inside:	move.w	(vdp_ctrl),d4
		btst	#bitVint,d4
		bne.s	.inside
		rts

; ====================================================================
; --------------------------------------------------------
; Routines to send task requests to 32X
; 
; Uses comm8,comm10,comm12
; --------------------------------------------------------

; ------------------------------------------------
; System_MdMars_Call
; 
; Do a single task, waits until it finishes
; ------------------------------------------------

; System_MdMars_Call:
; 		lea	(RAM_FifoMarsSgl),a6
; 		lea	(sysmars_reg),a5
; 		move.w	#1,(RAM_FifoMarsWrt).w
; 		movem.l	d0-d7,(a6)
; 		move.w	#0,(RAM_FifoMarsWrt).w
; 		move.w	#MAX_MDTSKARG-1,d6
; .wait_l:	move.b	comm15(a5),d0
; 		bne.s	.wait_l
; 		bsr.s	sysMdMars_go
; 		rts

; ------------------------------------------------
; Add task for 32X using d0-d7 registers
; 
; Input:
;    d0 - Task ID
; d1-d7 - Task arguments
; 
; Uses:
; a6
; ------------------------------------------------

System_MdMars_AddCall:
		cmp.w	#(MAX_MDTSKARG*MAX_MDTASKS)*4,(RAM_FifoMarsCnt).w
		bge.s	.ran_out
		move.w	#1,(RAM_FifoMarsWrt).w
		lea	(RAM_FifoToMars).l,a6
		adda	(RAM_FifoMarsCnt).w,a6
		movem.l	d0-d7,(a6)				; Send variables to RAM
		add.w	#MAX_MDTSKARG*4,(RAM_FifoMarsCnt).w
		move.w	#0,(RAM_FifoMarsWrt).w
.ran_out
		rts

; ; ------------------------------------------------
; ; System_MdMars_CheckBusy
; ; 
; ; Check if Slave CPU is busy doing the
; ; past tasks before sending new ones
; ; ------------------------------------------------
; 

System_MdMars_Call:
		bsr	System_MdMars_AddCall

; ------------------------------------------------
; System_MdMars_SendAll
;
; Starts sending queued tasks to SH2
; ------------------------------------------------

System_MdMars_SendAll:
		lea	(RAM_FifoToMars),a6
		lea	(sysmars_reg),a5
		clr.w	(RAM_FifoMarsCnt).w
.wait_l:
		nop
		nop
		move.b	comm15(a5),d0
		bne.s	.wait_l

		move.w	sr,d7
		move.w	#$2700,sr
		lea	comm8(a5),a4
		move.w	#$0201,(a4)		; MD ready | SH busy (init)
		move.w	standby(a5),d0		; SLAVE CMD interrupt
		bset	#1,d0
		move.w	d0,standby(a5)
.wait_cmd:	move.w	standby(a5),d0
		btst    #1,d0
		bne.s   .wait_cmd
		move.w	#(MAX_MDTSKARG*MAX_MDTASKS*4),d2
.loop:
		cmpi.b	#2,1(a4)		; SH ready?
		bne.s	.loop
		move.b	#1,(a4)			; MD is writing
		tst.w	d2
		beq.s	.exit
		move.l	(a6),d0
		clr.l	(a6)+
		move.w	d0,4(a4)
		swap	d0
		move.w	d0,2(a4)
		move.b	#2,(a4)			; MD is free
		sub.w	#4,d2
		bra.s	.loop
.exit:	
		move.b	#0,(a4)			; MD finished
		
		move.w	d7,sr
.mid_write:
		rts

; ====================================================================
; ----------------------------------------------------------------
; Game modes
; ----------------------------------------------------------------

; Initialize current screen mode
Mode_Init:
		bsr	Video_Clear
		lea	(RAM_ModeBuff),a4
		move.w	#(MAX_MDERAM/2)-1,d5
		moveq	#0,d4
.clr:
		move.w	d4,(a4)+
		dbf	d5,.clr
		rts
		
; ====================================================================
; ----------------------------------------------------------------
; Default interrupts
; ----------------------------------------------------------------

; --------------------------------------------------------
; VBlank
; --------------------------------------------------------

VInt_Default:
		movem.l	d0-a6,-(sp)
		bsr	System_Input
		add.l	#1,(RAM_FrameCount).l
		movem.l	(sp)+,d0-a6		
		rte

; --------------------------------------------------------
; HBlank
; --------------------------------------------------------

HInt_Default:
		rte
		
; ====================================================================
; ----------------------------------------------------------------
; System data
; ----------------------------------------------------------------

; Stuff like Sinewave data for MD will go here.
