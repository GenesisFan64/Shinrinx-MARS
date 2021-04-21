; ====================================================================
; ----------------------------------------------------------------
; Game Mode 0
; ----------------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Variables
; ------------------------------------------------------

var_MoveSpd	equ	$4000
CURY_MAX	equ	9

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
		
		struct RAM_ModeBuff
RAM_Cam_Xpos	ds.l 1
RAM_Cam_Ypos	ds.l 1
RAM_Cam_Zpos	ds.l 1
RAM_Cam_Xrot	ds.l 1
RAM_Cam_Yrot	ds.l 1
RAM_Cam_Zrot	ds.l 1
RAM_CamData	ds.l 1
RAM_CamFrame	ds.l 1
RAM_CamTimer	ds.l 1
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
; 		lea	str_Title(pc),a0
; 		move.l	#locate(0,1,1),d0
; 		bsr	Video_Print

		move.w	#1,(RAM_MdlCurrMd).w
; 		move.l	#GemaTrk_Yuki_patt,d0
; 		move.l	#GemaTrk_Yuki_blk,d1
; 		move.l	#GemaTrk_Yuki_ins,d2
; 		moveq	#5,d3
; 		moveq	#0,d4
; 		bsr	SoundReq_SetTrack
; 		moveq	#6,d1
; 		move.l	#PWM_STEREO,d2
; 		move.l	#PWM_STEREO_e,d3
; 		move.l	#0,d4
; 		move.l	#$100,d5
; 		move.l	#$000,d6
; 		move.l	#%10000011,d7
; 		move.l	#CmdTaskMd_PWM_SetChnl,d0
; 		bsr	System_MdMars_MstTask
	
		bset	#bitDispEnbl,(RAM_VdpRegs+1).l		; Enable display
		bsr	Video_Update

; ====================================================================
; ------------------------------------------------------
; Loop
; ------------------------------------------------------

.loop:
		bsr	System_VSync
; 		move.l	#$7C000003,(vdp_ctrl).l
; 		move.w	(RAM_BgCamCurr).l,d0
; 		lsr.w	#3,d0
; 		move.w	#0,(vdp_data).l
; 		move.w	d0,(vdp_data).l
; 		lea	str_Status(pc),a0
; 		move.l	#locate(0,1,25),d0
; 		bsr	Video_Print
		move.w	(RAM_MdlCurrMd).w,d0
		and.w	#%11111,d0
		add.w	d0,d0
		add.w	d0,d0
		jsr	.list(pc,d0.w)
		bra	.loop

; ====================================================================
; ------------------------------------------------------
; Mode sections
; ------------------------------------------------------

.list:
		bra.w	.mode0
		bra.w	.mode1
		
; --------------------------------------------------
; Mode 0
; --------------------------------------------------

.mode0:
		tst.w	(RAM_MdlCurrMd).w
		bmi	.mode0_loop
		or.w	#$8000,(RAM_MdlCurrMd).w

		move.l	#CmdTaskMd_ObjectClrAll,d0	; Clear ALL objects
		bsr	System_MdMars_SlvAddTask
		moveq	#0,d1
		move.l	#MARSOBJ_INTRO,d2
		moveq	#0,d3
		move.l	#CmdTaskMd_ObjectSet,d0
		bsr	System_MdMars_SlvAddTask	; Load object
		bsr	System_MdMars_SlvSendAll	; both SH2

		move.l	#CmdTaskMd_SetBitmap,d0		; 32X display OFF
		moveq	#0,d1
		bsr	System_MdMars_MstTask		; Wait until it finishes.
		move.l	#Palette_Intro,d1
		moveq	#0,d2
		move.w	#16,d3
		moveq	#0,d4
		move.l	#CmdTaskMd_LoadSPal,d0		; Load palette
		bsr	System_MdMars_MstAddTask
		move.l	#CmdTaskMd_SetBitmap,d0		; 32X display ON
		moveq	#1,d1
		bsr	System_MdMars_MstAddTask
		bsr	System_MdMars_MstSendAll

		move.l	#CAMERA_INTRO,(RAM_CamData).l
		bsr	MdMdl_CamAnimate

.mode0_loop:
		bsr	MdMdl_CamAnimate
		bpl.s	.stay
		move.w	#1,(RAM_MdlCurrMd).w
		rts
.stay:
		moveq	#0,d1
		move.l	(RAM_Cam_Xpos),d2
		move.l	(RAM_Cam_Ypos),d3
		move.l	(RAM_Cam_Zpos),d4
		move.l	(RAM_Cam_Xrot),d5
		move.l	(RAM_Cam_Yrot),d6
		move.l	(RAM_Cam_Zrot),d7
		move.l	#CmdTaskMd_CameraPos,d0		; Load map
		bsr	System_MdMars_SlvAddTask
		move.l	#CmdTaskMd_UpdModels,d0
		bsr	System_MdMars_SlvAddTask
		bsr	System_MdMars_SlvSendDrop
		rts

; --------------------------------------------------
; Mode 1
; --------------------------------------------------

.mode1:
		tst.w	(RAM_MdlCurrMd).w
		bmi	.mode1_loop
		or.w	#$8000,(RAM_MdlCurrMd).w
		clr.l	(RAM_Cam_Xpos).l
		clr.l	(RAM_Cam_Ypos).l
		clr.l	(RAM_Cam_Zpos).l
		clr.l	(RAM_Cam_Xrot).l
		clr.l	(RAM_Cam_Yrot).l
		clr.l	(RAM_Cam_Zrot).l
		move.l	#-$10000,(RAM_Cam_Ypos).l

		lea	MdPal_Bg(pc),a0
		move.w	#0,d0
		move.w	#16-1,d1
		bsr	Video_LoadPal
		lea	MdMap_Bg(pc),a0
		move.l	#locate(1,0,0),d0
		move.l	#mapsize(512,256),d1
		move.w	#1,d2
		bsr	Video_LoadMap
		move.l	#MdGfx_Bg,d0
		move.w	#(MdGfx_Bg_e-MdGfx_Bg),d1
		move.w	#1,d2
		bsr	Video_LoadArt

		moveq	#0,d1
		move.l	(RAM_Cam_Xpos),d2
		move.l	(RAM_Cam_Ypos),d3
		move.l	(RAM_Cam_Zpos),d4
		move.l	(RAM_Cam_Xrot),d5
		move.l	(RAM_Cam_Yrot),d6
		move.l	(RAM_Cam_Zrot),d7
		move.l	#CmdTaskMd_CameraPos,d0		; Load map
		bsr	System_MdMars_SlvAddTask
		move.l	#CmdTaskMd_ObjectClrAll,d0	; Clear ALL objects
		bsr	System_MdMars_SlvAddTask
		bsr	System_MdMars_SlvSendAll	; both SH2

		move.l	#CmdTaskMd_SetBitmap,d0		; 32X display OFF
		moveq	#0,d1
		bsr	System_MdMars_MstTask		; Wait until it finishes.
		move.l	#Palette_Map,d1
		moveq	#0,d2
		move.l	#256,d3
		move.l	#$8000,d4
		move.l	#CmdTaskMd_LoadSPal,d0		; Load palette
		bsr	System_MdMars_MstAddTask
		move.l	#TEST_LAYOUT,d1
		move.l	#CmdTaskMd_MakeMap,d0
		bsr	System_MdMars_MstAddTask	; Load map
		move.l	#CmdTaskMd_SetBitmap,d0		; 32X display ON
		moveq	#1,d1
		bsr	System_MdMars_MstAddTask
		bsr	System_MdMars_MstSendAll	; Send requests to
		bsr	.first_draw

.mode1_loop:
		move.l	#$7C000003,(vdp_ctrl).l
		move.w	(RAM_BgCamCurr).l,d0
		lsr.w	#3,d0
		move.w	#0,(vdp_data).l
		move.w	d0,(vdp_data).l
		lea	str_Status(pc),a0
		move.l	#locate(0,1,1),d0
		bsr	Video_Print

	; temporal camera
		moveq	#0,d6
		move.w	(Controller_1+on_hold).l,d7
		btst	#bitJoyUp,d7
		beq.s	.nou
		add.l	#var_MoveSpd,(RAM_Cam_Zpos).l
		moveq	#1,d6
.nou:
		btst	#bitJoyDown,d7
		beq.s	.nod
		add.l	#-var_MoveSpd,(RAM_Cam_Zpos).l
		moveq	#1,d6
.nod:
		btst	#bitJoyLeft,d7
		beq.s	.nol
		add.l	#-var_MoveSpd,(RAM_Cam_Xpos).l
		moveq	#1,d6
.nol:
		btst	#bitJoyRight,d7
		beq.s	.nor
		add.l	#var_MoveSpd,(RAM_Cam_Xpos).l
		moveq	#1,d6
.nor:
		btst	#bitJoyA,d7
		beq.s	.noa
		add.l	#-var_MoveSpd,(RAM_Cam_Xrot).l
		moveq	#1,d6
.noa:
		btst	#bitJoyB,d7
		beq.s	.nob
		add.l	#var_MoveSpd,(RAM_Cam_Xrot).l
		moveq	#1,d6
.nob:
; 		tst.w	d6
; 		beq.s	.nel
.first_draw:
		moveq	#0,d1
		move.l	(RAM_Cam_Xpos),d2
		move.l	(RAM_Cam_Ypos),d3
		move.l	(RAM_Cam_Zpos),d4
		move.l	(RAM_Cam_Xrot),d5
		move.l	(RAM_Cam_Yrot),d6
		move.l	(RAM_Cam_Zrot),d7
		move.l	#CmdTaskMd_CameraPos,d0		; Load map
		bsr	System_MdMars_SlvAddTask
		move.l	#CmdTaskMd_UpdModels,d0
		bsr	System_MdMars_SlvAddTask
		bsr	System_MdMars_SlvSendDrop
.nel:
		bne.s	.busy
		move.l	(RAM_Cam_Xrot),d1
		neg.l	d1
		lsr.l	#8,d1
		move.w	d1,(RAM_BgCamCurr).l
.busy:
		rts

; 		lea	.trklist(pc),a0
; 		lea	(RAM_SndPitch),a1
; 		move.w	(RAM_CurY),d5
; 		move.w	d5,d4
; 		add.w	d5,d5
; 		move.w	(a1,d5.w),d0
; 		lsl.w	#4,d0
; 		adda	d0,a0
; 		move.l	(a0)+,d0
; 		move.l	(a0)+,d1
; 		move.l	(a0)+,d2
; 		move.w	(a0)+,d3
; 		bra	SoundReq_SetTrack
; .trklist:
; 		dc.l GemaTrk_Yuki_patt
; 		dc.l GemaTrk_Yuki_blk
; 		dc.l GemaTrk_Yuki_ins
; 		dc.w 2,0
; 		dc.l TEST_PATTERN
; 		dc.l TEST_BLOCKS
; 		dc.l TEST_INSTR
; 		dc.w 3,0
; 		dc.l TEST_PATTERN_2
; 		dc.l TEST_BLOCKS_2
; 		dc.l TEST_INSTR_2
; 		dc.w 4,0

; ====================================================================
; ------------------------------------------------------
; Subroutines
; ------------------------------------------------------

; MdMdl_Update:
; 		cmp.w	#3,(RAM_CurY).w
; 		bge.s	.pwm_upd
; 		cmp.w	#2,(RAM_CurY).w
; 		bne.s	.upd_cont
; 		move.w	#$22,d0
; 		move.w	(RAM_SndPitch+4).w,d1
; 		bsr	Sound_Request
; 		bra.s	.upd_cont
; .pwm_upd:
; 		lea	(RAM_SndPitch+6),a0
; 		move.w	(a0)+,d1
; 		move.w	(a0)+,d2
; 		move.w	(a0)+,d3
; 		move.w	(a0)+,d4
; 		move.w	(a0)+,d5
; 		move.w	(a0)+,d6
; 		move.w	(a0)+,d7
; 		move.l	#CmdTaskMd_PWM_MultPitch,d0
; 		bsr	System_MdMars_MstTask
; 		
; .upd_cont:
; 		lea	str_StatusPtch(pc),a0
; 		move.l	#locate(0,10,3),d0
; 		bsr	Video_Print
; 		
; 		lea	str_LazCursor(pc),a0
; 		move.l	#locate(0,1,2),d0
; 		move.w	(RAM_CurY).w,d1
; 		add.b	d1,d0
; 		bra	Video_Print

MdMdl_CamAnimate:
		move.l	(RAM_CamData).l,d0		; If 0 == No animation
		beq.s	.no_camanim
		sub.l	#1,(RAM_CamTimer).l
		bpl.s	.no_camanim
		move.l	#1,(RAM_CamTimer).l		; TEMPORAL timer
		move.l	d0,a1
		move.l	(a1)+,d1
		move.l	(RAM_CamFrame).l,d0
		add.l	#1,d0
		cmp.l	d1,d0
		bne.s	.on_frames
		moveq	#-1,d0
		rts
.on_frames:
		move.l	d0,(RAM_CamFrame).l
		mulu.w	#$18,d0
		adda	d0,a1
		move.l	(a1)+,(RAM_Cam_Xpos).l
		move.l	(a1)+,(RAM_Cam_Ypos).l
		move.l	(a1)+,(RAM_Cam_Zpos).l
		move.l	(a1)+,(RAM_Cam_Xrot).l
		move.l	(a1)+,(RAM_Cam_Yrot).l
		move.l	(a1)+,(RAM_Cam_Zrot).l
		lsr.l	#7,d1
		move.w	d1,(RAM_BgCamera).l
.no_camanim:
		moveq	#0,d0
		rts
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

; str_LazCursor:	dc.b " ",$A,">",$A," ",0
; 		align 2
; str_Title:	dc.b "GEMA Sound tester",$A,$A
; 		dc.b " Track 1 ????",$A
; 		dc.b " Track 2 ????",$A
; 		dc.b "     DAC ????",$A
; 		dc.b "  PWM 01 ????",$A
; 		dc.b "      02 ????",$A
; 		dc.b "      03 ????",$A
; 		dc.b "      04 ????",$A
; 		dc.b "      05 ????",$A
; 		dc.b "      06 ????",$A
; 		dc.b "      07 ????",0
; 		dc.b "                             ",0
; 		align 2
; str_StatusPtch:	dc.b "\\w",$A
; 		dc.b "\\w",$A
; 		dc.b "\\w",$A
; 		dc.b "\\w",$A
; 		dc.b "\\w",$A
; 		dc.b "\\w",$A
; 		dc.b "\\w",$A
; 		dc.b "\\w",$A
; 		dc.b "\\w",$A
; ; 		dc.b "\\w",$A
; ; 		dc.b "\\w",$A
; ; 		dc.b "\\w",$A
; ; 		dc.b "\\w",$A
; ; 		dc.b "\\w",$A
; ; 		dc.b "\\w",$A
; ; 		dc.b "\\w",$A
; 		dc.b "\\w",0
; 		dc.l RAM_SndPitch
; 		dc.l RAM_SndPitch+2
; 		dc.l RAM_SndPitch+4
; 		dc.l RAM_SndPitch+6
; 		dc.l RAM_SndPitch+8
; 		dc.l RAM_SndPitch+10
; 		dc.l RAM_SndPitch+12
; 		dc.l RAM_SndPitch+14
; 		dc.l RAM_SndPitch+16
; 		dc.l RAM_SndPitch+18
; ; 		dc.l RAM_SndPitch+20
; ; 		dc.l RAM_SndPitch+22
; ; 		dc.l RAM_SndPitch+24
; ; 		dc.l RAM_SndPitch+26
; ; 		dc.l RAM_SndPitch+28
; ; 		dc.l RAM_SndPitch+30
; ; 		dc.l RAM_SndPitch+32
; 		align 2
str_Status:
		dc.b "\\w \\w \\w \\w       MD: \\l",$A
		dc.b "\\w \\w \\w \\w",$A
		dc.b "\\l \\l \\l \\l",0
		dc.l sysmars_reg+comm0
		dc.l sysmars_reg+comm2
		dc.l sysmars_reg+comm4
		dc.l sysmars_reg+comm6
		dc.l RAM_FrameCount
		dc.l sysmars_reg+comm8
		dc.l sysmars_reg+comm10
		dc.l sysmars_reg+comm12
		dc.l sysmars_reg+comm14
		dc.l RAM_Cam_Xpos,RAM_Cam_Ypos,RAM_Cam_Zpos
		dc.l RAM_Cam_Xrot;,RAM_Cam_Yrot,RAM_Cam_Zrot		
		align 4

MdPal_Bg:
		binclude "data/md/bg/bg_pal.bin"
		align 2
MdMap_Bg:
		binclude "data/md/bg/bg_map.bin"
		align 2
