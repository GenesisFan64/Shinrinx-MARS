; ====================================================================
; ----------------------------------------------------------------
; Game Mode 0
; ----------------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Variables
; ------------------------------------------------------

var_MoveSpd	equ	$2000
CURY_MAX	equ	16

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

; 		struct 0
; cam2_x_pos	ds.l 1
; cam2_y_pos	ds.l 1
; cam2_z_pos	ds.l 1
; cam2_x_rot	ds.l 1
; cam2_y_rot	ds.l 1
; cam2_z_rot	ds.l 1
; cam2_animdata	ds.l 1
; cam2_animframe	ds.l 1
; cam2_animtimer	ds.l 1
; sizeof_mdcam	ds.l 0
; 		finish
		
		struct RAM_ModeBuff
RAM_RotX	ds.l 1
RAM_MdlCurrMd	ds.w 1
RAM_BgCamera	ds.w 1
RAM_BgCamCurr	ds.w 1
RAM_CurY	ds.w 1
RAM_SndPitch	ds.w 17
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
		move.l	#locate(0,1,1),d0
		bsr	Video_Print
		bset	#bitDispEnbl,(RAM_VdpRegs+1).l		; Enable display
		bsr	Video_Update

; 		lea	(RAM_MdCamera),a0
; 		moveq	#0,d0
; 		move.l	d0,cam2_x_pos(a0)
; 		move.l	#-$8000,cam2_y_pos(a0)
; 		move.l	#-$30000,cam2_z_pos(a0)
; 		move.l	d0,cam2_x_rot(a0)
; 		move.l	d0,cam2_y_rot(a0)
; 		move.l	d0,cam2_z_rot(a0)
; 		move.l	#CAMERA_ANIM,(RAM_MdCamera+cam2_animdata)
		
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
		move.l	#locate(0,1,25),d0
		bsr	Video_Print
		move.w	(RAM_MdlCurrMd).w,d0
		and.w	#$FF,d0
		add.w	d0,d0
		add.w	d0,d0
		bsr	.mode0;.list(pc,d0.w)
		bra	.loop

; ====================================================================
; ------------------------------------------------------
; Mode sections
; ------------------------------------------------------

.list:
		bra.w	.mode0
		bra.w	.mode0
		
; --------------------------------------------------

.mode0:
		tst.w	(RAM_MdlCurrMd).w
		bmi	.mode0_loop
		or.w	#$8000,(RAM_MdlCurrMd).w

		move.l	#CmdTaskMd_SetBitmap,d0		; 32X display OFF
		moveq	#0,d1
		bsr	System_MdMars_MstTask		; Wait until it finishes.
		move.l	#CmdTaskMd_ObjectClrAll,d0	; Clear ALL objects
		bsr	System_MdMars_SlvAddTask
		move.l	#CmdTaskMd_ObjectSet,d0		; Load 2 objects
		moveq	#0,d1
		move.l	#MARSOBJ_SMOK,d2
		moveq	#96,d3
		bsr	System_MdMars_SlvAddTask
		moveq	#1,d1
		move.l	#MARSOBJ_SMOK2,d2
		moveq	#0,d3
		bsr	System_MdMars_SlvAddTask		
		move.l	#CmdTaskMd_LoadSPal,d0		; Load palette
		move.l	#Palette_Map,d1
		moveq	#0,d2
		move.w	#96,d3
		moveq	#0,d4
		bsr	System_MdMars_MstAddTask
		move.l	#Palette_Puyo,d1
		move.w	#96,d2
		move.w	#160,d3
		bsr	System_MdMars_MstAddTask
		move.l	#CmdTaskMd_SetBitmap,d0		; 32X display ON
		moveq	#1,d1
		bsr	System_MdMars_MstAddTask
		bsr	System_MdMars_MstSendAll	; Send requests to
		bsr	System_MdMars_SlvSendAll	; both SH2

		lea	(RAM_SndPitch),a0
		move.w	#$100,d0
		move.w	#17-1,d1
.initvals:
		move.w	d0,(a0)+
		dbf	d1,.initvals
		bsr	MdMdl_Update

.mode0_loop:
		move.w	(Controller_1+on_press).l,d7
		btst	#bitJoyC,d7
		beq.s	.noc
		bsr	.play_sample
.noc:
		move.w	(Controller_1+on_press).l,d7
		btst	#bitJoyLeft,d7
		beq.s	.nol
		lea	(RAM_SndPitch),a0
		move.w	(RAM_CurY).w,d0
		add.w	d0,d0
		sub.w	#1,(a0,d0.w)
		bsr	MdMdl_Update
.nol:
		move.w	(Controller_1+on_press).l,d7
		btst	#bitJoyRight,d7
		beq.s	.nor
		lea	(RAM_SndPitch),a0
		move.w	(RAM_CurY).w,d0
		add.w	d0,d0
		add.w	#1,(a0,d0.w)
		bsr	MdMdl_Update
.nor:

		move.w	(Controller_1+on_press).l,d7
		btst	#bitJoyUp,d7
		beq.s	.nou
		tst.w	(RAM_CurY).w
		beq.s	.nou
		sub.w	#1,(RAM_CurY).w
		bsr	MdMdl_Update
.nou:
		move.w	(Controller_1+on_press).l,d7
		btst	#bitJoyDown,d7
		beq.s	.nod
		cmp.w	#CURY_MAX,(RAM_CurY).w
		bge.s	.nod
		add.w	#1,(RAM_CurY).w
		bsr	MdMdl_Update
.nod:

	; XYZM
		move.w	(Controller_1+on_press).l,d7
		move.w	d7,d6
		and.w	#JoyY,d6
		beq.s	.noy
		lea	(RAM_SndPitch),a0
		move.w	(RAM_CurY).w,d0
		add.w	d0,d0
		sub.w	#$10,(a0,d0.w)
		bsr	MdMdl_Update
.noy:
		move.w	(Controller_1+on_press).l,d7
		move.w	d7,d6
		and.w	#JoyZ,d6
		beq.s	.noz
		lea	(RAM_SndPitch),a0
		move.w	(RAM_CurY).w,d0
		add.w	d0,d0
		add.w	#$10,(a0,d0.w)
		bsr	MdMdl_Update
.noz:
	; BG Visual updates
		move.l	#CmdTaskMd_ObjectPos,d0		; Cmnd $0A: Modify object pos and rot
		moveq	#0,d1				; Slot
		move.l	#$9000,d2			; X
		move.l	#-$6000,d3			; Y
		move.l	#-$40000,d4			; Z
		move.l	(RAM_RotX),d5
		move.l	#0,d6
		move.l	#0,d7
		bsr	System_MdMars_SlvAddTask
		move.l	#$6000,d3			; Y
		moveq	#1,d1				; Slot		
		bsr	System_MdMars_SlvAddTask		
		bsr	System_MdMars_SlvSendDrop
		add.l	#$2000,(RAM_RotX)
		rts

; 	
.play_sample:
		tst.w	(RAM_CurY).w
		bne.s	.pwm_test
		move.l	#TEST_WAV,d0
		move.l	#(TEST_WAV_E-TEST_WAV),d1
		move.l	#0,d2
		move.w	(RAM_SndPitch).w,d3
		bsr	SoundReq_SetSample
		bra	MdMdl_Update
.pwm_test:
		lea	(RAM_SndPitch+2),a0
		move.w	(RAM_CurY).w,d1
		sub.w	#1,d1
		move.w	d1,d0
		add.w	d0,d0
		moveq	#0,d5
		move.w	(a0,d0.w),d5

		move.l	#PWM_STEREO,d2
		move.l	#PWM_STEREO_e,d3
		move.l	d2,d4
		moveq	#0,d6
		moveq	#%111,d7
		move.l	#CmdTaskMd_PWM_SetChnl,d0
		bra	System_MdMars_MstTask

; 		moveq	#1,d1
; 		move.l	#PWM_RIGHT,d2
; 		move.l	#PWM_RIGHT_e,d3
; 		move.l	d2,d4
; 		move.l	#$100,d5
; 		moveq	#0,d6
; 		moveq	#%01,d7
; 		move.l	#CmdTaskMd_SetPWM,d0
; 		bsr	System_MdMars_MstAddTask
; 		bsr	System_MdMars_MstSendAll
; 		
; .nox:

; ====================================================================
; ------------------------------------------------------
; Subroutines
; ------------------------------------------------------

MdMdl_Update:
		tst.w	(RAM_CurY).w
		bne.s	.pwm_upd
		move.w	#$22,d0
		move.w	(RAM_SndPitch).w,d1
		bsr	Sound_Request
		bra.s	.upd_cont
.pwm_upd:
		lea	(RAM_SndPitch+2),a0
		move.w	(a0)+,d1	; 1 | 2
		swap	d1
		move.w	(a0)+,d1
		move.w	(a0)+,d2	; 3 | 4
		swap	d2
		move.w	(a0)+,d2
		move.w	(a0)+,d3	; 5 | 6
		swap	d3
		move.w	(a0)+,d3
		move.w	(a0)+,d4	; 7 | 8
		swap	d4
		move.w	(a0)+,d4
		moveq	#0,d5
		move.l	#CmdTaskMd_PWM_MultPitch,d0
		bsr	System_MdMars_MstAddTask
		move.w	(a0)+,d1	; 1 | 2
		swap	d1
		move.w	(a0)+,d1
		move.w	(a0)+,d2	; 3 | 4
		swap	d2
		move.w	(a0)+,d2
		move.w	(a0)+,d3	; 5 | 6
		swap	d3
		move.w	(a0)+,d3
		move.w	(a0)+,d4	; 7 | 8
		swap	d4
		move.w	(a0)+,d4
		moveq	#8,d5
		move.l	#CmdTaskMd_PWM_MultPitch,d0
		bsr	System_MdMars_MstAddTask
		bsr	System_MdMars_MstSendAll
		
.upd_cont:
		lea	str_StatusPtch(pc),a0
		move.l	#locate(0,10,3),d0
		bsr	Video_Print
		
		lea	str_LazCursor(pc),a0
		move.l	#locate(0,1,2),d0
		move.w	(RAM_CurY).w,d1
		add.b	d1,d0
		bra	Video_Print

; MdMdl_CamAnimate:
; 		lea	(RAM_MdCamera),a0
; 		move.l	cam2_animdata(a0),d0		; If 0 == No animation
; 		beq.s	.no_camanim
; 		sub.l	#1,cam2_animtimer(a0)
; 		bpl.s	.no_camanim
; 		move.l	#1+1,cam2_animtimer(a0)		; TEMPORAL timer
; 		move.l	d0,a1
; 		move.l	(a1)+,d1
; 		move.l	cam2_animframe(a0),d0
; 		add.l	#1,d0
; 		cmp.l	d1,d0
; 		bne.s	.on_frames
; 		moveq	#0,d0
; .on_frames:
; 		move.l	d0,cam2_animframe(a0)
; 		mulu.w	#$18,d0
; 		adda	d0,a1
; 		move.l	(a1)+,cam2_x_pos(a0)
; 		move.l	(a1)+,cam2_y_pos(a0)
; 		move.l	(a1)+,cam2_z_pos(a0)
; 		move.l	(a1)+,d1
; 		move.l	d1,d0
; 		neg.l	d0
; 		move.l	d0,cam2_x_rot(a0)
; 		move.l	(a1)+,cam2_y_rot(a0)
; 		move.l	(a1)+,cam2_z_rot(a0)
; 		lsr.l	#7,d1
; 		move.w	d1,(RAM_BgCamera).l
; .no_camanim:
; 		rts
; 
; MdMdl1_Usercontrol:
; 		move.l	#var_MoveSpd,d5
; 		move.l	#-var_MoveSpd,d6
; 		move.w	(Controller_2+on_hold),d7
; 		btst	#bitJoyUp,d7
; 		beq.s	.no_up
; 		lea	(RAM_MdCamera),a0
; 		move.l	cam2_z_pos(a0),d0
; 		add.l	d5,d0
; 		move.l	d0,cam2_z_pos(a0)
; .no_up:
; 		btst	#bitJoyDown,d7
; 		beq.s	.no_dw
; 		lea	(RAM_MdCamera),a0
; 		move.l	cam2_z_pos(a0),d0
; 		add.l	d6,d0
; 		move.l	d0,cam2_z_pos(a0)
; .no_dw:
; 		btst	#bitJoyLeft,d7
; 		beq.s	.no_lf
; 		lea	(RAM_MdCamera),a0
; 		move.l	cam2_x_pos(a0),d0
; 		add.l	d6,d0
; 		move.l	d0,cam2_x_pos(a0)
; .no_lf:
; 		btst	#bitJoyRight,d7
; 		beq.s	.no_rg
; 		lea	(RAM_MdCamera),a0
; 		move.l	cam2_x_pos(a0),d0
; 		add.l	d5,d0
; 		move.l	d0,cam2_x_pos(a0)
; .no_rg:
; 
; 		btst	#bitJoyB,d7
; 		beq.s	.no_a
; 		lea	(RAM_MdCamera),a0
; 		move.l	cam2_x_rot(a0),d0
; 		move.l	d6,d1
; 		add.l	d1,d0
; 		move.l	d0,cam2_x_rot(a0)
; 		lsr.l	#7,d0
; 		neg.l	d0
; 		move.w	d0,(RAM_BgCamera).l
; .no_a:
; 		btst	#bitJoyC,d7
; 		beq.s	.no_b
; 		lea	(RAM_MdCamera),a0
; 		move.l	cam2_x_rot(a0),d0
; 		move.l	d5,d1
; 		add.l	d1,d0
; 		move.l	d0,cam2_x_rot(a0)
; 		lsr.l	#7,d0
; 		neg.l	d0
; 		move.w	d0,(RAM_BgCamera).l
; .no_b:
; 	; Reset all
; ; 		btst	#bitJoyC,d7
; ; 		beq.s	.no_c
; ; 		;move.w	#1,(RAM_MdMdlsUpd).l
; ; 		lea	(RAM_MdCamera),a0
; ; 		moveq	#0,d0
; ; 		move.l	d0,cam2_x_pos(a0)
; ; 		move.l	d0,cam2_y_pos(a0)
; ; 		move.l	d0,cam2_z_pos(a0)
; ; 		move.l	d0,cam2_x_rot(a0)
; ; 		move.l	d0,cam2_y_rot(a0)
; ; 		move.l	d0,cam2_z_rot(a0)
; ; .no_c:
; 
; 
; 	; Up/Down
; 		move.w	d7,d4
; 		and.w	#JoyY,d4
; 		beq.s	.no_x
; 		;move.w	#1,(RAM_MdMdlsUpd).l
; 		lea	(RAM_MdCamera),a0
; 		move.l	cam2_y_pos(a0),d0
; 		add.l	d5,d0
; 		move.l	d0,cam2_y_pos(a0)
; .no_x:
; 		move.w	d7,d4
; 		and.w	#JoyZ,d4
; 		beq.s	.no_y
; 		;move.w	#1,(RAM_MdMdlsUpd).l
; 		lea	(RAM_MdCamera),a0
; 		move.l	cam2_y_pos(a0),d0
; 		add.l	d6,d0
; 		move.l	d0,cam2_y_pos(a0)
; .no_y:
; 		rts

; 		lea	(RAM_MdCamera),a0
; 		move.l	#CmdTaskMd_CameraPos,d0		; Cmnd $0D: Set camera positions
; 		moveq	#0,d1
; 		move.l	cam2_x_pos(a0),d2
; 		move.l	cam2_y_pos(a0),d3
; 		move.l	cam2_z_pos(a0),d4
; 		move.l	cam2_x_rot(a0),d5
; 		move.l	cam2_y_rot(a0),d6
; 		move.l	cam2_z_rot(a0),d7
; 		bsr	System_MdMars_SlvAddTask

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

str_LazCursor:	dc.b " ",$A,">",$A," ",0
		align 2
str_Title:	dc.b "Project Shinrinx + GEMA Z80x68KxSH2",$A,$A
		dc.b "  DAC 01 ????",$A
		dc.b "  PWM 01 ????",$A
		dc.b "      02 ????",$A
		dc.b "      03 ????",$A
		dc.b "      04 ????",$A
		dc.b "      05 ????",$A
		dc.b "      06 ????",$A
		dc.b "      07 ????",$A
		dc.b "      08 ????",$A
		dc.b "      09 ????",$A
		dc.b "      10 ????",$A
		dc.b "      11 ????",$A
		dc.b "      12 ????",$A
		dc.b "      13 ????",$A
		dc.b "      14 ????",$A
		dc.b "      15 ????",$A
		dc.b "      16 ????",$A
		dc.b "                             ",0
		align 2
str_StatusPtch:	dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",0
		dc.l RAM_SndPitch
		dc.l RAM_SndPitch+2
		dc.l RAM_SndPitch+4
		dc.l RAM_SndPitch+6
		dc.l RAM_SndPitch+8
		dc.l RAM_SndPitch+10
		dc.l RAM_SndPitch+12
		dc.l RAM_SndPitch+14
		dc.l RAM_SndPitch+16
		dc.l RAM_SndPitch+18
		dc.l RAM_SndPitch+20
		dc.l RAM_SndPitch+22
		dc.l RAM_SndPitch+24
		dc.l RAM_SndPitch+26
		dc.l RAM_SndPitch+28
		dc.l RAM_SndPitch+30
		dc.l RAM_SndPitch+32
		align 2
str_Status:
		dc.b "\\w \\w \\w \\w       MD: \\l",$A
		dc.b "\\w \\w \\w \\w",0
		dc.l sysmars_reg+comm0
		dc.l sysmars_reg+comm2
		dc.l sysmars_reg+comm4
		dc.l sysmars_reg+comm6
		dc.l RAM_FrameCount
		dc.l sysmars_reg+comm8
		dc.l sysmars_reg+comm10
		dc.l sysmars_reg+comm12
		dc.l sysmars_reg+comm14
		align 4
