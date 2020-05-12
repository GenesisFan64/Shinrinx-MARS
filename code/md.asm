; ====================================================================
; ----------------------------------------------------------------
; MD code (at $FF0000)
; ----------------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Global RAM
; ------------------------------------------------------

		struct RAM_MdGlobal
RAM_MdCamera	ds.b sizeof_camera
RAM_MdModels	ds.b sizeof_mdlobj		; info on /system/mars/video.asm
RAM_BgCamera	ds.l 1
RAM_BgCamCurr	ds.l 1
RAM_MdMdlsUpd	ds.w 1
RAM_MdGlbExmpl	ds.w 1
sizeof_mdglbl	ds.l 0
		finish

; ====================================================================
; ------------------------------------------------------
; Variables
; ------------------------------------------------------

Var_example	equ	1234

; ====================================================================
; ------------------------------------------------------
; Structs
; ------------------------------------------------------

; 		struct 0
; strc_xpos	ds.w 1
; strc_ypos	ds.w 1
; 		finish

; ====================================================================
; ------------------------------------------------------
; RAM for current screen mode
; ------------------------------------------------------

		struct RAM_ModeBuff
ScrnTest_Info	ds.w 1
		finish

; ====================================================================
; --------------------------------------------------------
; Include system features
; --------------------------------------------------------

		include	"system/md/system.asm"
		include	"system/md/video.asm"
		include	"system/md/sound.asm"

; ====================================================================
; --------------------------------------------------------
; Initialize system
; --------------------------------------------------------

MD_Main:
		bsr 	Sound_init
		bsr 	Video_init
		bsr	System_Init
		
; ====================================================================
; ------------------------------------------------------
; Code start
; ------------------------------------------------------
	
		move.w	#$2700,sr
		bsr	Mode_Init
		bsr	Video_PrintInit
; 		lea	str_Title(pc),a0
; 		move.l	#locate(0,0,0),d0
; 		bsr	Video_Print
		bset	#bitDispEnbl,(RAM_VdpRegs+1).l		; Enable display
		bsr	Video_Update
		
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
		move.l	#locate(0,0,0),d0
		bsr	Video_Print

	; Foward/Backward/Left/Right

		move.l	#$100,d5
		move.l	#-$100,d6
		
		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyUp,d7
		beq.s	.no_up
		move.w	#1,(RAM_MdMdlsUpd).l
		lea	(RAM_MdCamera),a0
		move.l	cam_z_pos(a0),d0
		add.l	d5,d0
		move.l	d0,cam_z_pos(a0)
.no_up:
		btst	#bitJoyDown,d7
		beq.s	.no_dw
		move.w	#1,(RAM_MdMdlsUpd).l
		lea	(RAM_MdCamera),a0
		move.l	cam_z_pos(a0),d0
		add.l	d6,d0
		move.l	d0,cam_z_pos(a0)
.no_dw:
		btst	#bitJoyLeft,d7
		beq.s	.no_lf
		move.w	#1,(RAM_MdMdlsUpd).l
		lea	(RAM_MdCamera),a0
		move.l	cam_x_pos(a0),d0
		add.l	d6,d0
		move.l	d0,cam_x_pos(a0)
.no_lf:
		btst	#bitJoyRight,d7
		beq.s	.no_rg
		move.w	#1,(RAM_MdMdlsUpd).l
		lea	(RAM_MdCamera),a0
		move.l	cam_x_pos(a0),d0
		add.l	d5,d0
		move.l	d0,cam_x_pos(a0)
.no_rg:

		btst	#bitJoyA,d7
		beq.s	.no_a
		move.w	#1,(RAM_MdMdlsUpd).l
		lea	(RAM_MdCamera),a0
		move.l	cam_x_rot(a0),d0
		add.l	d6,d0
		move.l	d0,cam_x_rot(a0)
		move.w	d6,d0
		add.w	#$10,(RAM_BgCamera).l
.no_a:
		btst	#bitJoyB,d7
		beq.s	.no_b
		move.w	#1,(RAM_MdMdlsUpd).l
		lea	(RAM_MdCamera),a0
		move.l	cam_x_rot(a0),d0
		add.l	d5,d0
		move.l	d0,cam_x_rot(a0)
		sub.w	#$10,(RAM_BgCamera).l
.no_b:
	; Reset all
		btst	#bitJoyC,d7
		beq.s	.no_c
		move.w	#1,(RAM_MdMdlsUpd).l
		lea	(RAM_MdCamera),a0
		moveq	#0,d0
		move.l	d0,cam_x_pos(a0)
		move.l	d0,cam_y_pos(a0)
		move.l	d0,cam_z_pos(a0)
		move.l	d0,cam_x_rot(a0)
		move.l	d0,cam_y_rot(a0)
		move.l	d0,cam_z_rot(a0)
.no_c:


	; Up/Down
		move.w	d7,d4
		and.w	#JoyX,d4
		beq.s	.no_x
		move.w	#1,(RAM_MdMdlsUpd).l
		lea	(RAM_MdCamera),a0
		move.l	cam_y_pos(a0),d0
		add.l	d5,d0
		move.l	d0,cam_y_pos(a0)
.no_x:
		move.w	d7,d4
		and.w	#JoyY,d4
		beq.s	.no_y
		move.w	#1,(RAM_MdMdlsUpd).l
		lea	(RAM_MdCamera),a0
		move.l	cam_y_pos(a0),d0
		add.l	d6,d0
		move.l	d0,cam_y_pos(a0)
.no_y:

		tst.w	(RAM_MdMdlsUpd).l
		beq	.loop
		clr.w	(RAM_MdMdlsUpd).l
		bsr	MdMars_TrsnfrMdls
		bra	.loop
		
; ====================================================================
; ------------------------------------------------------
; Subroutines
; ------------------------------------------------------

MdMars_TrsnfrMdls:
		lea	(sysmars_reg),a0
		tst.b	comm15(a0)
		bne.s	.no_start
		move.b	#1,comm15(a0)
		lea	(sysmars_reg+comm8),a0
		lea	(RAM_MdCamera),a1
		move.w	#(sizeof_camera/4)-1,d2
.paste:
		nop
		nop
		nop
		nop
		nop
		move.w	(a0),d0
		bne.s	.paste
		move.w	(a1)+,d0
		move.w	d0,2(a0)
		move.w	(a1)+,d0
		move.w	d0,4(a0)
		move.w	#1,(a0)
		dbf	d2,.paste

.busy_2:	move.w	(a0),d0
		bne.s	.busy_2
		move.w	#2,(a0)
		move.w	(RAM_BgCamera).l,(RAM_BgCamCurr).l
.no_start:
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
str_Title:	dc.b "Project Shinrinx-MARS",0
		align 2

str_Status:
		dc.b "\\w \\w \\w \\w         MD: \\l",$A
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
		
MdPal_Bg:
		binclude "data/md/bg/bg_pal.bin"
		align 2
MdMap_Bg:
		binclude "data/md/bg/bg_map.bin"
		align 2

