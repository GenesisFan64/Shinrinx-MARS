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

var_MoveSpd	equ	$1000

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

; 		struct RAM_ModeBuff
; ScrnTest_Info	ds.w 1
; 		finish

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
		
		move.l	#CAMERA_ANIM,(RAM_MdCamera+cam_animdata)
; 		move.l	#0,(RAM_MdCamera+cam_animdata)

		lea	(RAM_MdCamera),a0
		moveq	#0,d0
		move.l	d0,cam_x_pos(a0)
		move.l	d0,cam_y_pos(a0)
		move.l	d0,cam_x_rot(a0)
		move.l	d0,cam_y_rot(a0)
		move.l	d0,cam_z_rot(a0)
		move.l	d0,cam_z_pos(a0)
.no_c:

		move.w	#1,(RAM_MdMdlsUpd).l
		
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
		
	; Camera animation
		lea	(RAM_MdCamera),a0
		move.l	cam_animdata(a0),d0		; If 0 == No animation
		beq.s	.no_camanim
		sub.l	#1,cam_animtimer(a0)
		bpl.s	.no_camanim
		move.l	#1+1,cam_animtimer(a0)		; TEMPORAL timer
		move.l	d0,a1
		move.l	(a1)+,d1
		move.l	cam_animframe(a0),d0
		add.l	#1,d0
		cmp.l	d1,d0
		bne.s	.on_frames
		moveq	#0,d0
.on_frames:
		move.l	d0,cam_animframe(a0)
		mulu.w	#$18,d0
		adda	d0,a1
		move.l	(a1)+,cam_x_pos(a0)
		move.l	(a1)+,cam_y_pos(a0)
		move.l	(a1)+,cam_z_pos(a0)
		move.l	(a1)+,d1
		neg.l	d1
		move.l	d1,cam_x_rot(a0)
		move.l	(a1)+,cam_y_rot(a0)
		move.l	(a1)+,cam_z_rot(a0)
		neg.l	d1
		lsr.l	#7,d1
		move.w	d1,(RAM_BgCamera).l
		move.w	#1,(RAM_MdMdlsUpd).l
.no_camanim:
		move.w	(RAM_BgCamera).l,(RAM_BgCamCurr).l

	; Foward/Backward/Left/Right
		bsr	MdMdl_Usercontrol
		tst.w	(RAM_MdMdlsUpd).l
		beq	.loop
		clr.w	(RAM_MdMdlsUpd).l
		
		lea	(RAM_MdCamera),a0
		move.l	#1,d0			; Slave task 1, set camera
		move.l	#0,d1			; Camera slot (TODO)	
		move.l	cam_x_pos(a0),d2	; X pos
		move.l	cam_y_pos(a0),d3	; Y pos
		move.l	cam_z_pos(a0),d4	; Z pos
		move.l	cam_x_rot(a0),d5	; X rot
		move.l	cam_y_rot(a0),d6	; Y rot
		move.l	cam_z_rot(a0),d7	; Z rot
		bsr	MdToMarsTask_Single
		bra	.loop
		
; ====================================================================
; ------------------------------------------------------
; Subroutines
; ------------------------------------------------------

MdToMarsTask_Single:
		movem.l	d0-d7,(RAM_FifoToMars).l	; Send variables to RAM
		lea	(sysmars_reg),a0
.is_busy:	move.b	comm15(a0),d0
		bmi.s	.is_busy
		move.b	#1,comm15(a0)
		move.w	(sysmars_reg+standby).l,d0	; SLAVE CMD interrupt
		bset	#1,d0
		move.w	d0,(sysmars_reg+standby).l
		lea	(sysmars_reg+comm8),a0		; a0 - comm8
		lea	(RAM_FifoToMars),a1
		move.w	#MAX_MDTSKARG-1,d2
.paste:
		nop
		nop
		move.w	(a0),d0				; wait if free
		bne.s	.paste
		move.w	(a1)+,d0
		move.w	d0,2(a0)
		move.w	(a1)+,d0
		move.w	d0,4(a0)
		move.w	#1,(a0)				; send it
		dbf	d2,.paste
.busy_2:	move.w	(a0),d0				; last wait
		bne.s	.busy_2
		move.w	#2,(a0)				; send finished
.no_start:
		rts

MdMdl_Usercontrol:
		move.l	#var_MoveSpd,d5
		move.l	#-var_MoveSpd,d6
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
		move.l	d6,d1
		add.l	d1,d0
		move.l	d0,cam_x_rot(a0)
		lsr.l	#7,d0
		neg.l	d0
		move.w	d0,(RAM_BgCamera).l
.no_a:
		btst	#bitJoyB,d7
		beq.s	.no_b
		move.w	#1,(RAM_MdMdlsUpd).l
		lea	(RAM_MdCamera),a0
		move.l	cam_x_rot(a0),d0
		move.l	d5,d1
		add.l	d1,d0
		move.l	d0,cam_x_rot(a0)
		lsr.l	#7,d0
		neg.l	d0
		move.w	d0,(RAM_BgCamera).l
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
		dc.b "\\w \\w \\w \\w",$A
		dc.b "\\l \\l \\l",$A
		dc.b "\\l \\l \\l",0
		dc.l sysmars_reg+comm0
		dc.l sysmars_reg+comm2
		dc.l sysmars_reg+comm4
		dc.l sysmars_reg+comm6
		dc.l RAM_FrameCount
		dc.l sysmars_reg+comm8
		dc.l sysmars_reg+comm10
		dc.l sysmars_reg+comm12
		dc.l sysmars_reg+comm14
		dc.l RAM_MdCamera+cam_x_pos
		dc.l RAM_MdCamera+cam_y_pos
		dc.l RAM_MdCamera+cam_z_pos
		dc.l RAM_MdCamera+cam_x_rot
		dc.l RAM_MdCamera+cam_y_rot
		dc.l RAM_MdCamera+cam_z_rot
		align 4
		
MdPal_Bg:
		binclude "data/md/bg/bg_pal.bin"
		align 2
MdMap_Bg:
		binclude "data/md/bg/bg_map.bin"
		align 2
