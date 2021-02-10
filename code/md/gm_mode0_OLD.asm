; ====================================================================
; ----------------------------------------------------------------
; Game Mode 0
; ----------------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Variables
; ------------------------------------------------------

var_MoveSpd	equ	$1000

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
; RAM_MdModels	ds.b sizeof_mdlobj		; info on /system/mars/video.asm
RAM_BgCamera	ds.l 1
RAM_BgCamCurr	ds.l 1
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

; 		move.l	#CAMERA_ANIM,(RAM_MdCamera+cam2_animdata)
		move.l	#0,(RAM_MdCamera+cam2_animdata)

		lea	(RAM_MdCamera),a0
		moveq	#0,d0
		move.l	d0,cam2_x_pos(a0)
		move.l	#-$10000,cam2_y_pos(a0)
		move.l	d0,cam2_x_rot(a0)
		move.l	d0,cam2_y_rot(a0)
		move.l	d0,cam2_z_rot(a0)
		move.l	d0,cam2_z_pos(a0)
		move.w	#1,d0
		move.l	#TEST_LAYOUT,d1
		bsr	System_MdMars_Add
; 		;move.w	#1,(RAM_MdMdlsUpd).l
; 		bsr	System_MdMars_SendAll
		
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
		move.l	#locate(0,28,0),d0
		bsr	Video_Print

		lea	(RAM_MdCamera),a0
		moveq	#9,d0				; Task $09, set camera
		moveq	#0,d1				; Camera slot (TODO)	
		move.l	cam2_x_pos(a0),d2		; X pos
		move.l	cam2_y_pos(a0),d3		; Y pos
		move.l	cam2_z_pos(a0),d4		; Z pos
		move.l	cam2_x_rot(a0),d5		; X rot
		move.l	cam2_y_rot(a0),d6		; Y rot
		move.l	cam2_z_rot(a0),d7		; Z rot
		bsr	System_MdMars_Add
		bsr	System_MdMars_SendDrop
.no_req:

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
		bra.s	.cont_rendr
.no_camanim:
		bsr	MdMdl_Usercontrol		; Foward/Backward/Left/Right
.cont_rendr:
		bra	.loop
		
; ====================================================================
; ------------------------------------------------------
; Subroutines
; ------------------------------------------------------

MdMdl_Usercontrol:
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

		btst	#bitJoyA,d7
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
		btst	#bitJoyB,d7
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
		btst	#bitJoyC,d7
		beq.s	.no_c
		;move.w	#1,(RAM_MdMdlsUpd).l
		lea	(RAM_MdCamera),a0
		moveq	#0,d0
		move.l	d0,cam2_x_pos(a0)
		move.l	d0,cam2_y_pos(a0)
		move.l	d0,cam2_z_pos(a0)
		move.l	d0,cam2_x_rot(a0)
		move.l	d0,cam2_y_rot(a0)
		move.l	d0,cam2_z_rot(a0)
.no_c:


	; Up/Down
		move.w	d7,d4
		and.w	#JoyX,d4
		beq.s	.no_x
		;move.w	#1,(RAM_MdMdlsUpd).l
		lea	(RAM_MdCamera),a0
		move.l	cam2_y_pos(a0),d0
		add.l	d5,d0
		move.l	d0,cam2_y_pos(a0)
.no_x:
		move.w	d7,d4
		and.w	#JoyY,d4
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
str_Title:	dc.b "Project Shinrinx + GEMA",0
		align 2

str_Status:
		dc.b "MD: \\l",0
		dc.l RAM_FrameCount
		align 4
		
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
