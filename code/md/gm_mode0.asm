; ====================================================================
; ----------------------------------------------------------------
; Game Mode 0
; ----------------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Variables
; ------------------------------------------------------

var_MoveSpd	equ	$2000

; ====================================================================
; ------------------------------------------------------
; Structs
; ------------------------------------------------------

		struct 0
strc_xpos	ds.w 1
strc_ypos	ds.w 1
		finish

; ====================================================================
; ------------------------------------------------------
; This mode's RAM
; ------------------------------------------------------

		struct 0
cam2_x_pos	ds.l 1
cam2_y_pos	ds.l 1
cam2_z_pos	ds.l 1
cam2_x_rot	ds.l 1
cam2_y_rot	ds.l 1
cam2_z_rot	ds.l 1
cam2_animdata	ds.l 1
cam2_animframe	ds.l 1
cam2_animtimer	ds.l 1
sizeof_mdcam	ds.l 0
		finish
		
		struct RAM_ModeBuff
RAM_MdCamera	ds.b sizeof_mdcam
RAM_RotX	ds.l 1
RAM_MdlCurrMd	ds.w 1
RAM_BgCamera	ds.w 1
RAM_BgCamCurr	ds.w 1
sizeof_mdglbl	ds.l 0
		finish
		
; ====================================================================
; ------------------------------------------------------
; Code start
; ------------------------------------------------------

MD_GmMode0:
		move.w	#$2700,sr
		bsr	Mode_Init
		bsr	Video_PrintInit
		lea	str_Title(pc),a0
		move.l	#locate(0,0,0),d0
		bsr	Video_Print
		bset	#bitDispEnbl,(RAM_VdpRegs+1).l		; Enable display
		bsr	Video_Update

		lea	(RAM_MdCamera),a0
		moveq	#0,d0
		move.l	d0,cam2_x_pos(a0)
		move.l	d0,cam2_y_pos(a0)
		move.l	d0,cam2_x_rot(a0)
		move.l	d0,cam2_y_rot(a0)
		move.l	d0,cam2_z_rot(a0)
		move.l	d0,cam2_z_pos(a0)

; 		moveq	#1,d0
; 		move.l	#MARSOBJ_SMOK,d1
; 		moveq	#0,d2
; 		moveq	#0,d3
; 		move.l	#0,d4
; 		moveq	#0,d5
; 		moveq	#0,d6
; 		moveq	#0,d7		
; 		bsr	System_MdMars_Add
; 		bsr	System_MdMars_SendDrop

		bsr	MdMdl_Update

; ====================================================================
; ------------------------------------------------------
; Loop
; ------------------------------------------------------

.loop:
		bsr	System_VSync
		move.l	#$7C000003,(vdp_ctrl).l
		move.w	(RAM_BgCamCurr).l,d0
		lsr.w	#3,d0
		move.w	#0,(vdp_data).l
		move.w	d0,(vdp_data).l
		lea	str_Status(pc),a0
		move.l	#locate(0,32,0),d0
		bsr	Video_Print
		move.w	(RAM_MdlCurrMd).w,d0
		and.w	#$FF,d0
		add.w	d0,d0
		move.w	.list(pc,d0.w),d0
		jsr	.list(pc,d0.w)
		bra	.loop

; ====================================================================
; ------------------------------------------------------
; Mode sections
; ------------------------------------------------------

.list:
		dc.w	.mode0-.list
		dc.w	.mode1-.list
		
; --------------------------------------------------

.mode0:
		tst.w	(RAM_MdlCurrMd).w
		bmi.s	.mode0_loop
		or.w	#$8000,(RAM_MdlCurrMd).w
		moveq	#$F,d0				; Clear ALL models
		bsr	System_MdMars_Add
		moveq	#9,d0				; Reset camera
		moveq	#0,d1
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		moveq	#0,d5
		moveq	#0,d6
		moveq	#0,d7
		bsr	System_MdMars_Add
		moveq	#8,d0
		moveq	#0,d1				; NO layout
		bsr	System_MdMars_Add
		moveq	#1,d0				; Set NEW object
		moveq	#0,d1
		move.l	#MARSOBJ_SMOK,d2
		bsr	System_MdMars_Add
		bsr	MdMdl_Update
.mode0_loop:
		move.w	(Controller_1+on_press),d7
		and.w	#JoyA,d7
		beq.s	.no_prss
		move.w	#1,(RAM_MdlCurrMd).w
		bra	MdMdl_Update
.no_prss:
		moveq	#4,d0
		moveq	#0,d1			; Slot
		moveq	#0,d2			; X
		moveq	#0,d3			; Y
		move.l	#-$30000,d4		; Z
		move.l	(RAM_RotX),d5
		move.l	(RAM_RotX),d6
		move.l	(RAM_RotX),d7
		lsr.l	#1,d5
		bsr	System_MdMars_Add
		bsr	System_MdMars_SendDrop
		add.l	#$2000,(RAM_RotX)
		rts

; --------------------------------------------------

.mode1:
		tst.w	(RAM_MdlCurrMd).w
		bmi.s	.mode1_loop
		or.w	#$8000,(RAM_MdlCurrMd).w
		
		move.l	#CAMERA_ANIM,(RAM_MdCamera+cam2_animdata)
		moveq	#$F,d0
		bsr	System_MdMars_Add
		moveq	#8,d0
		move.l	#TEST_LAYOUT,d1
		bsr	System_MdMars_Add
		bsr	System_MdMars_SendHold
		bsr	MdMdl_Update
.mode1_loop:
		move.w	(Controller_1+on_press),d7
		and.w	#JoyA,d7
		beq.s	.no_prss1
		move.w	#0,(RAM_MdlCurrMd).w
		rts
.no_prss1:
; 		bsr	MdMdl_CamAnimate
		bsr	MdMdl1_Usercontrol		; Foward/Backward/Left/Right
		lea	(RAM_MdCamera),a0
		moveq	#9,d0
		moveq	#0,d1
		move.l	cam2_x_pos(a0),d2
		move.l	cam2_y_pos(a0),d3
		move.l	cam2_z_pos(a0),d4
		move.l	cam2_x_rot(a0),d5
		move.l	cam2_y_rot(a0),d6
		move.l	cam2_z_rot(a0),d7
		bsr	System_MdMars_Add
		bsr	System_MdMars_SendDrop
		rts

; ====================================================================
; ------------------------------------------------------
; Subroutines
; ------------------------------------------------------

MdMdl_Update:
		lea	str_Mode0(pc),a0
		move.w	(RAM_MdlCurrMd).w,d0
		and.w	#$FF,d0
		beq.s	.mod0
		lea	str_Mode1(pc),a0
.mod0:
		move.l	#locate(0,0,2),d0
		bra	Video_Print

MdMdl_CamAnimate:
		lea	(RAM_MdCamera),a0
		move.l	cam2_animdata(a0),d0		; If 0 == No animation
		beq.s	.no_camanim
		sub.l	#1,cam2_animtimer(a0)
		bpl.s	.no_camanim
		move.l	#1+1,cam2_animtimer(a0)		; TEMPORAL timer
		move.l	d0,a1
		move.l	(a1)+,d1
		move.l	cam2_animframe(a0),d0
		add.l	#1,d0
		cmp.l	d1,d0
		bne.s	.on_frames
		moveq	#0,d0
.on_frames:
		move.l	d0,cam2_animframe(a0)
		mulu.w	#$18,d0
		adda	d0,a1
		move.l	(a1)+,cam2_x_pos(a0)
		move.l	(a1)+,cam2_y_pos(a0)
		move.l	(a1)+,cam2_z_pos(a0)
		move.l	(a1)+,d1
		move.l	d1,d0
		neg.l	d0
		move.l	d0,cam2_x_rot(a0)
		move.l	(a1)+,cam2_y_rot(a0)
		move.l	(a1)+,cam2_z_rot(a0)
		lsr.l	#7,d1
		move.w	d1,(RAM_BgCamera).l
.no_camanim:
		rts

MdMdl1_Usercontrol:
		move.l	#var_MoveSpd,d5
		move.l	#-var_MoveSpd,d6
		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyUp,d7
		beq.s	.no_up
		;move.w	#1,(RAM_MdMdlsUpd).l
		lea	(RAM_MdCamera),a0
		move.l	cam2_z_pos(a0),d0
		add.l	d5,d0
		move.l	d0,cam2_z_pos(a0)
.no_up:
		btst	#bitJoyDown,d7
		beq.s	.no_dw
		;move.w	#1,(RAM_MdMdlsUpd).l
		lea	(RAM_MdCamera),a0
		move.l	cam2_z_pos(a0),d0
		add.l	d6,d0
		move.l	d0,cam2_z_pos(a0)
.no_dw:
		btst	#bitJoyLeft,d7
		beq.s	.no_lf
		;move.w	#1,(RAM_MdMdlsUpd).l
		lea	(RAM_MdCamera),a0
		move.l	cam2_x_pos(a0),d0
		add.l	d6,d0
		move.l	d0,cam2_x_pos(a0)
.no_lf:
		btst	#bitJoyRight,d7
		beq.s	.no_rg
		;move.w	#1,(RAM_MdMdlsUpd).l
		lea	(RAM_MdCamera),a0
		move.l	cam2_x_pos(a0),d0
		add.l	d5,d0
		move.l	d0,cam2_x_pos(a0)
.no_rg:

		btst	#bitJoyB,d7
		beq.s	.no_a
		;move.w	#1,(RAM_MdMdlsUpd).l
		lea	(RAM_MdCamera),a0
		move.l	cam2_x_rot(a0),d0
		move.l	d6,d1
		add.l	d1,d0
		move.l	d0,cam2_x_rot(a0)
		lsr.l	#7,d0
		neg.l	d0
		move.w	d0,(RAM_BgCamera).l
.no_a:
		btst	#bitJoyC,d7
		beq.s	.no_b
		;move.w	#1,(RAM_MdMdlsUpd).l
		lea	(RAM_MdCamera),a0
		move.l	cam2_x_rot(a0),d0
		move.l	d5,d1
		add.l	d1,d0
		move.l	d0,cam2_x_rot(a0)
		lsr.l	#7,d0
		neg.l	d0
		move.w	d0,(RAM_BgCamera).l
.no_b:
	; Reset all
; 		btst	#bitJoyC,d7
; 		beq.s	.no_c
; 		;move.w	#1,(RAM_MdMdlsUpd).l
; 		lea	(RAM_MdCamera),a0
; 		moveq	#0,d0
; 		move.l	d0,cam2_x_pos(a0)
; 		move.l	d0,cam2_y_pos(a0)
; 		move.l	d0,cam2_z_pos(a0)
; 		move.l	d0,cam2_x_rot(a0)
; 		move.l	d0,cam2_y_rot(a0)
; 		move.l	d0,cam2_z_rot(a0)
; .no_c:


	; Up/Down
		move.w	d7,d4
		and.w	#JoyY,d4
		beq.s	.no_x
		;move.w	#1,(RAM_MdMdlsUpd).l
		lea	(RAM_MdCamera),a0
		move.l	cam2_y_pos(a0),d0
		add.l	d5,d0
		move.l	d0,cam2_y_pos(a0)
.no_x:
		move.w	d7,d4
		and.w	#JoyZ,d4
		beq.s	.no_y
		;move.w	#1,(RAM_MdMdlsUpd).l
		lea	(RAM_MdCamera),a0
		move.l	cam2_y_pos(a0),d0
		add.l	d6,d0
		move.l	d0,cam2_y_pos(a0)
.no_y:
		rts

; ====================================================================
; ------------------------------------------------------
; Interrupts
; ------------------------------------------------------

; --------------------------------------------------
; Custom VBlank
; --------------------------------------------------

; --------------------------------------------------
; Custom HBlank
; --------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; DATA
; 
; short stuff goes here
; ------------------------------------------------------

		align 2
str_Title:	dc.b "Project Shinrinx + GEMA Sound",0
		align 2
str_Status:	dc.b "MD: \\w",0
		dc.l RAM_FrameCount+2
		align 4
str_Mode0:	dc.b "< Mode 0: GEMA sound tester >",0
		align 2
str_Mode1:	dc.b "< Mode 1: Map layout sample >",0
		align 2

; str_Status:
; 		dc.b "\\w \\w \\w \\w         MD: \\l",$A
; 		dc.b "\\w \\w \\w \\w",$A
; 		dc.b "\\l \\l \\l",$A
; 		dc.b "\\l \\l \\l",0
; 		dc.l sysmars_reg+comm0
; 		dc.l sysmars_reg+comm2
; 		dc.l sysmars_reg+comm4
; 		dc.l sysmars_reg+comm6
; 		dc.l RAM_FrameCount
; 		dc.l sysmars_reg+comm8
; 		dc.l sysmars_reg+comm10
; 		dc.l sysmars_reg+comm12
; 		dc.l sysmars_reg+comm14
; 		dc.l RAM_MdCamera+cam2_x_pos
; 		dc.l RAM_MdCamera+cam2_y_pos
; 		dc.l RAM_MdCamera+cam2_z_pos
; 		dc.l RAM_MdCamera+cam2_x_rot
; 		dc.l RAM_MdCamera+cam2_y_rot
; 		dc.l RAM_MdCamera+cam2_z_rot
; 		align 4
		
; MdPal_Bg:
; 		binclude "data/md/bg/bg_pal.bin"
; 		align 2
; MdMap_Bg:
; 		binclude "data/md/bg/bg_map.bin"
; 		align 2
