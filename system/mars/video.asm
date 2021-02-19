; ====================================================================
; ----------------------------------------------------------------
; MARS Video
; ----------------------------------------------------------------

; MARS Polygons
; 
; type format:
;   0 - end-of-list
;  -1 - skip polygon (already drawn)
; $03 - triangle
; $04 - quad

; ----------------------------------------
; Settings
; ----------------------------------------

MAX_FACES	equ	256	; Maximum polygon faces (models,sprites) to store on buffer
MAX_SVDP_PZ	equ	384	; This list is for both read and write, increase the value if needed
MAX_MODELS	equ	64	; Note: First 9 models are reserved for layout map
MAX_ZDIST	equ	-$2000	; Max drawing distance (-Z max)
LAY_WIDTH	equ	$10*2	; Layout data width * 2

; ----------------------------------------
; Variables
; ----------------------------------------

SCREEN_WIDTH	equ	320
SCREEN_HEIGHT	equ	224

; MSB
PLGN_TEXURE	equ	%10000000
PLGN_TRI	equ	%01000000
PLGN_SPRITE	equ	%00100000

; ----------------------------------------
; Structs
; ----------------------------------------

; model objects
		struct 0
mdl_data	ds.l 1			; Model data pointer, zero: model disabled
mdl_x_pos	ds.l 1			; X position $000000.00
mdl_y_pos	ds.l 1			; Y position $000000.00
mdl_z_pos	ds.l 1			; Z position $000000.00
mdl_x_rot	ds.l 1			; X rotation $000000.00
mdl_y_rot	ds.l 1			; Y rotation $000000.00
mdl_z_rot	ds.l 1			; Z rotation $000000.00
mdl_animdata	ds.l 1			; Model animation data pointer, zero: no animation
mdl_animframe	ds.l 1			; Current frame in animation
mdl_animtimer	ds.l 1			; Animation timer
mdl_animspd	ds.l 1			; Animation speed
sizeof_mdlobj	ds.l 0
		finish
		
; field view camera
		struct 0
cam_x_pos	ds.l 1			; X position $000000.00
cam_y_pos	ds.l 1			; Y position $000000.00
cam_z_pos	ds.l 1			; Z position $000000.00
cam_x_rot	ds.l 1			; X rotation $000000.00
cam_y_rot	ds.l 1			; Y rotation $000000.00
cam_z_rot	ds.l 1			; Z rotation $000000.00
cam_animdata	ds.l 1			; Model animation data pointer, zero: no animation
cam_animframe	ds.l 1			; Current frame in animation
cam_animtimer	ds.l 1			; Animation timer
cam_animspd	ds.l 1			; Animation speed
sizeof_camera	ds.l 0
		finish
		
		struct 0
mdllay_data	ds.l 1			; Model layout data, zero: Don't use layout
mdllay_x	ds.l 1			; X position
mdllay_y	ds.l 1			; Y position
mdllay_z	ds.l 1			; Z position
mdllay_x_last	ds.l 1			; LAST saved X position
mdllay_y_last	ds.l 1			; LAST saved Y position
mdllay_z_last	ds.l 1			; LAST saved Z position
mdllay_xr_last	ds.l 1			; LAST saved X rotation
sizeof_layout	ds.l 0
		finish

		struct 0
plypz_ypos	ds.l 1			; Ytop | Ybottom
plypz_xl	ds.l 1
plypz_xl_dx	ds.l 1
plypz_xr	ds.l 1
plypz_xr_dx	ds.l 1
plypz_src_xl	ds.l 1
plypz_src_xl_dx	ds.l 1
plypz_src_yl	ds.l 1
plypz_src_yl_dx	ds.l 1
plypz_src_xr	ds.l 1
plypz_src_xr_dx	ds.l 1
plypz_src_yr	ds.l 1
plypz_src_yr_dx	ds.l 1
plypz_mtrl	ds.l 1
plypz_mtrlopt	ds.l 1			; Type | Option
sizeof_plypz	ds.l 0
		finish

		struct 0
polygn_type	ds.l 1		; %MST0 0000 wwww wwww | Type bits and Material option (Width or PalIncr)
polygn_mtrl	ds.l 1		; Material Type: Color (0-255) or Texture data address
polygn_points	ds.l 4*2	; X/Y positions
polygn_srcpnts	ds.w 4*2	; X/Y texture points (16-bit), ignored on solidcolor
sizeof_polygn	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; Init MARS Video
; ----------------------------------------------------------------

MarsVideo_Init:
		sts	pr,@-r15
		mov	#_sysreg,r4
		mov 	#FM,r0		; Set SVDP permission to SH2
  		mov.b	r0,@(adapter,r4)
		mov 	#_vdpreg,r4
		bsr	.this_fb	; Init line tables for both framebuffers
		nop
		bsr	.this_fb
		nop
; 		mov	#2,r0
; 		mov.w	r0,@(marsGbl_BitmapSet,gbr)
; 		mov	#1,r0
; 		mov.w	r0,@(marsGbl_BitmapReq,gbr)
		mov	#1,r0
		mov.b	r0,@(bitmapmd,r4)
		lds	@r15+,pr
		rts
		nop
		align 4

; ------------------------------------------------
; Init current framebuffer
; ------------------------------------------------

.this_fb:
 		mov	#_framebuffer,r1
		mov	#$200/2,r0	; START line data
		mov	#240,r2		; Vertical lines to set
		mov	r0,r3		; Increment by (copy from r0)
.loop:		mov.w	r0,@r1
		add	#2,r1
		add	r3,r0
		dt	r2
		bf	.loop
.fb_wait1:	mov.w   @($A,r4),r0	; Swap for next table
		tst     #2,r0
		bf      .fb_wait1
		mov.w   @($A,r4), r0
		xor     #1,r0
		mov.w   r0,@($A,r4)
		and     #1,r0
		mov     r0,r1
.wait_result:
		mov.w   @($A,r4),r0
		and     #1,r0
		cmp/eq  r0,r1
		bf      .wait_result
		rts
		nop
		align 4
		
; ------------------------------------
; MarsVideo_ClearFrame
; 
; Clear the current framebuffer
; ------------------------------------

MarsVideo_ClearFrame:
		mov	#_vdpreg,r1
.wait2		mov.w	@(10,r1),r0		; Wait for FEN to clear
		and	#%10,r0
		cmp/eq	#2,r0
		bt	.wait2

		mov	#255,r2			; 256 words per pass
		mov	#$100,r3		; Starting address
		mov	#0,r4			; Clear to zero
		mov	#256,r5			; Increment address by 256
		mov	#((512*240)/256)/2,r6	; 140 passes
.loop
		mov	r2,r0
		mov.w	r0,@(4,r1)		; Set length
		mov	r3,r0
		mov.w	r0,@(6,r1)		; Set address
		mov	r4,r0
		mov.w	r0,@(8,r1)		; Set data
		add	r5,r3
		
.wait		mov.w	@(10,r1),r0		; Wait for FEN to clear
		and	#%10,r0
		cmp/eq	#2,r0
		bt	.wait
		dt	r6
		bf	.loop
		rts
		nop
		align 4

; ------------------------------------
; MarsVideo_FrameSwap
; ------------------------------------

MarsVideo_FrameSwap:
		mov.l	#_vdpreg,r2
.wait_fb:
		mov.w	@($A,r2),r0
		tst	#2,r0
		bf	.wait_fb
		mov.w	@($A,r2),r0
		xor	#1,r0
		mov.w	r0,@($A,r2)
		and	#1,r0
		mov	r0,r1
.wait_result:
		mov.w	@($A,r2),r0
		and	#1,r0
		cmp/eq	r0,r1
		bf	.wait_result
		rts
		nop
		align 4

; ------------------------------------
; MarsVdp_LoadPal
; 
; Load palette to RAM
; then the Palette will be transfered
; on VBlank
; 
; Input:
; r1 - Palette data
; r2 - Start index
; r3 - Number of colors
; r4 - OR value ($0000 or $8000)
;
; Uses:
; r0,r4-r6
; ------------------------------------

MarsVideo_LoadPal:
		stc	sr,@-r15
		mov	#$F0,r0
		ldc	r0,sr
		mov 	r1,r5
		mov 	#RAM_Mars_Palette,r6
		mov 	r2,r0
		shll	r0
		add 	r0,r6
		mov 	r3,r7
.loop:
		mov.w	@r5+,r0
		or	r4,r0
		mov.w	r0,@r6
		dt	r7
		bf/s	.loop
		add 	#2,r6
		ldc	@r15+,sr
		rts
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; 3D MODEL RENDERER
; ----------------------------------------------------------------

; ------------------------------------------------
; Object layout routines
; ------------------------------------------------

; ----------------------------------------
; Read layout
; ----------------------------------------

MarsLay_Read:
		sts	pr,@-r15
		mov	#RAM_Mars_ObjLayout,r14
		mov	#RAM_Mars_ObjCamera,r13
		mov	#RAM_Mars_Objects,r12
		mov	@(mdllay_data,r14),r0
		cmp/pl	r0
		bf	.no_lay
		mov	r0,r11

		mov	#0,r10				; r10 - Update counter
		mov	#-$100000,r9			;  r9 - MAX Z block size
		mov	#-$100000,r8			;  r8 - MAX Y block size	
		mov	#-$100000,r7			;  r7 - MAX X block size
		mov	#-$8000,r6			;  r6 - X Rotation update point

		mov	@(mdllay_z_last,r14),r5
		mov	@(cam_z_pos,r13),r0
		and	r9,r0
		and	r9,r5
		cmp/eq	r0,r5
		bt	.no_z_upd
; 		add	r9,r5
; 		neg	r5,r4
; 		cmp/gt	r5,r0
; 		bf	.set_z_upd
; 		cmp/ge	r4,r0
; 		bf	.no_z_upd
; .set_z_upd:
		and	r9,r0
		mov	r0,@(mdllay_z_last,r14)
		add	#1,r10
.no_z_upd:

		mov	@(mdllay_y_last,r14),r5
		mov	@(cam_y_pos,r13),r0
		and	r8,r0
		and	r8,r5
		cmp/eq	r0,r5
		bt	.no_y_upd
; 		add	r8,r5
; 		neg	r5,r4
; 		cmp/gt	r5,r0
; 		bf	.set_y_upd
; 		cmp/ge	r4,r0
; 		bf	.no_y_upd
; .set_y_upd:
		and	r8,r0
		mov	r0,@(mdllay_y_last,r14)
		add	#1,r10
.no_y_upd:

		mov	@(mdllay_x_last,r14),r5
		mov	@(cam_x_pos,r13),r0
		and	r7,r0
		and	r7,r5
		cmp/eq	r0,r5
		bt	.no_x_upd
; 		add	r7,r5
; 		neg	r5,r4
; 		cmp/gt	r5,r0
; 		bf	.set_x_upd
; 		cmp/ge	r4,r0
; 		bf	.no_x_upd
; .set_x_upd:
		and	r7,r0
		mov	r0,@(mdllay_x_last,r14)
		add	#1,r10
.no_x_upd:

		mov	@(mdllay_xr_last,r14),r5
		mov	@(cam_x_rot,r13),r0
		and	r6,r0
		and	r6,r5
		cmp/eq	r0,r5
		bt	.no_xr_upd
; 		add	r6,r5
; 		neg	r5,r4
; 		cmp/gt	r5,r0
; 		bf	.set_xr_upd
; 		cmp/ge	r4,r0
; 		bf	.no_xr_upd
; .set_xr_upd:
		and	r6,r0
		mov	r0,@(mdllay_xr_last,r14)
		add	#1,r10
.no_xr_upd:

		cmp/pl	r10
		bf	.no_lay
		bsr	MarsLay_Draw
		nop
.no_lay:
		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; r1 - layout data pointer
MarsLay_Make:
		mov	#RAM_Mars_ObjLayout,r14
		mov	#RAM_Mars_ObjCamera,r13
		xor	r0,r0
		mov	r1,@(mdllay_data,r14)
		mov	r0,@(mdllay_x_last,r14)
		mov	r0,@(mdllay_y_last,r14)
		mov	r0,@(mdllay_z_last,r14)
		mov	r0,@(mdllay_x,r14)
		mov	r0,@(mdllay_y,r14)
		mov	r0,@(mdllay_z,r14)
MarsLay_Draw:
		mov	#RAM_Mars_Objects,r10
		mov	r10,r2
		mov	#sizeof_mdlobj,r3
		mov	#0,r0
		mov	#9,r4
.clrold:
		mov	r0,@(mdl_data,r2)
		mov	r0,@(mdl_x_pos,r2)
		mov	r0,@(mdl_y_pos,r2)
		mov	r0,@(mdl_z_pos,r2)
		mov	r0,@(mdl_x_rot,r2)
		mov	r0,@(mdl_y_rot,r2)
		mov	r0,@(mdl_z_rot,r2)
		dt	r4
		bf/s	.clrold
		add	r3,r2

	; r13 - Layout Ids
	; r12 - Layout model list
		mov	#0,r4
		mov	@(mdllay_data,r14),r13
		mov	@r13+,r12
		mov	.center_val,r0			; list center point
		add	r0,r13
		mov	@(mdllay_x_last,r14),r1
		mov	@(mdllay_z_last,r14),r2
		mov	#LAY_WIDTH,r0
		shlr16	r1
		shlr16	r2
		exts	r1,r1
		exts	r2,r2
	rept 3
		shar	r1
		shar	r2
	endm
		shar	r2			; extra shift
		muls	r0,r2
		sts	macl,r0
		add	r1,r13
		sub	r0,r13
		mov	@(mdllay_xr_last,r14),r0
		shlr16	r0
		and	#$3F,r0
		shll2	r0
		mov	#.list,r1
		mov	@(r0,r1),r0
		jmp	@r0
		nop
		align 4
.center_val:	dc.l (LAY_WIDTH*6)+(2*5)

.list:
		dc.l .front
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		
		dc.l .down
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left

		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front

; r5 - numof pieces
; uses: r6,r7
.do_piece:
		mov	r1,@-r15
		mov	r13,@-r15
		mov	#$100000,r6
.nxt_one:
		xor	r4,r4
		mov.w	@r13+,r0
		cmp/pl 	r0
		bf	.blank_mdl
		mov	r0,r7
		shlr8	r0
		shlr2	r0
		shlr	r0
		and	#%11100,r0
		mov	#.xrotlist,r8
		mov	@(r8,r0),r8
		mov	r7,r0
		add	#-1,r0
		shll2	r0
		shll	r0
		mov	#$1FFF,r7
		and	r7,r0
		mov	@(r12,r0),r4
		mov	#$40000000,r0
		or	r0,r4
.blank_mdl:
		mov	r1,@(mdl_x_pos,r10)
		mov	r2,@(mdl_y_pos,r10)
		mov	r3,@(mdl_z_pos,r10)
		mov	r8,@(mdl_x_rot,r10)	
		mov	r4,@(mdl_data,r10)
		add	#sizeof_mdlobj,r10
		dt	r5
		bf/s	.nxt_one
		add	r6,r1
		mov	@r15+,r13
		mov	@r15+,r1
		rts
		nop
		align 4
.xrotlist:	dc.l 0
		dc.l $100000
		dc.l $200000
		dc.l $300000

; o X X X o
; o X X X o
; o X C X o
; o - - - o
; o o o o o
.front:
		mov	#-$100000,r1
		mov	#0,r2
		mov	#-$200000,r3
		add	#(1*2),r13
		mov	#$100000,r11

		sts	pr,@-r15
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		lds	@r15+,pr
		rts
		nop
		align 4

; front right view
; o o X X X
; o - X X X
; o - C X X
; o - - - o
; o o o o o
.front_fr:
		mov	#0,r1
		mov	#0,r2
		mov	#-$200000,r3
		add	#(2*2),r13
		mov	#$100000,r11
		sts	pr,@-r15
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		lds	@r15+,pr
		rts
		nop
		align 4


; right view/down
; o o o o o
; o - - - o
; o - C X X
; o - X X X
; o o X X X
.right_dw:
		mov	#0,r1
		mov	#0,r2
		mov	#-$100000,r3
		mov	#(2*2)+(LAY_WIDTH),r0
		add	r0,r13
		mov	#$100000,r11
		sts	pr,@-r15
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		lds	@r15+,pr
		rts
		nop
		align 4

; o o o o o
; o - - - o
; o X C X o
; o X X X o
; o X X X o
.down:
		mov	#0,r1
		mov	#0,r2
		mov	#-$100000,r3
		mov	#(2*2)+(LAY_WIDTH*1),r0
		add	r0,r13
		mov	#$100000,r11
		sts	pr,@-r15
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		lds	@r15+,pr
		rts
		nop
		align 4

; o o o o o
; o - - - o
; X X C - o
; X X X - o
; X X X o o
.down_left:
		mov	#-$100000,r1
		mov	#0,r2
		mov	#-$100000,r3
		mov	#(1*2)+(LAY_WIDTH*1),r0
		add	r0,r13
		mov	#$100000,r11
		sts	pr,@-r15
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		lds	@r15+,pr
		rts
		nop
		align 4


; X X X o o
; X X X - o
; X X C - o
; o - - - o
; o o o o o
.front_lf:
		mov	#-$100000,r1
		mov	#0,r2
		mov	#-$200000,r3
		add	#(1*2),r13
		mov	#$100000,r11
		sts	pr,@-r15
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------
; MarsMdl_Init
; 
; Reset ALL objects
; ------------------------------------------------

MarsMdl_Init:
		mov	#RAM_Mars_Objects,r1
		mov	#(sizeof_mdlobj*MAX_MODELS)/4,r2
		mov	#0,r0
.clnup:
		mov	r0,@r1
		dt	r2
		bf/s	.clnup
		add	#4,r1
		rts
		nop
		align 4
		ltorg

MarsMdl_ReadModel:
		sts	pr,@-r15

		mov	@(mdl_animdata,r14),r13
		cmp/pl	r13
		bf	.no_anim
		mov	@(mdl_animtimer,r14),r0
		add	#-1,r0
		cmp/pl 	r0
		bt	.wait_camanim
		mov	@r13+,r2
		mov	@(mdl_animframe,r14),r0
		add	#1,r0
		cmp/eq	r2,r0
		bf	.on_frames
		xor	r0,r0
.on_frames:
		mov	r0,r1
		mov	r0,@(mdl_animframe,r14)
		mov	#$18,r0
		mulu	r0,r1
		sts	macl,r0 	
		add	r0,r13
		mov	@r13+,r1
		mov	@r13+,r2
		mov	@r13+,r3
		mov	@r13+,r4
		mov	@r13+,r5
		mov	@r13+,r6
		neg	r4,r4
		mov	r1,@(mdl_x_pos,r14)
		mov	r2,@(mdl_y_pos,r14)
		mov	r3,@(mdl_z_pos,r14)
		mov	r4,@(mdl_x_rot,r14)
		mov	r5,@(mdl_y_rot,r14)
		mov	r6,@(mdl_z_rot,r14)
		mov	#1,r0				; TEMPORAL timer
.wait_camanim:
		mov	r0,@(mdl_animtimer,r14)	
.no_anim:

	; Now start reading
		mov	@(marsGbl_CurrFacePos,gbr),r0
		mov	r0,r13				; r13 - output faces
		mov	#$3FFFFFFF,r0
		mov	@(mdl_data,r14),r12		; r12 - model header
		and	r0,r12
		mov 	@(8,r12),r11			; r11 - face data
		mov 	@(4,r12),r10			; r10 - vertice data (X,Y,Z)
		mov.w	@r12,r9				;  r9 - Number of faces used on model
		mov	@(marsGbl_CurrZList,gbr),r0	;  r8 - Zlist for sorting
		mov	r0,r8
.next_face:
		mov.w	@(marsGbl_MdlFacesCntr,gbr),r0	; Ran out of space to store faces?
		mov	#MAX_FACES,r1
		cmp/ge	r1,r0
		bf	.can_build
		bra	.exit_model
		nop
.can_build:
		mov.w	@r11+,r4			; Read type from model
		mov	#3,r7				; r7 - Current polygon type: triangle (3)
		mov	r4,r0
		shlr8	r0
		tst	#PLGN_TRI,r0			; Model face uses triangle?
		bf	.set_tri
		add	#1,r7				; Face is quad, r7 = 4 points
.set_tri:
		cmp/pl	r4				; Faces uses texture?
		bt	.solid_type

; --------------------------------
; Set texture material
; --------------------------------

		mov	@($C,r12),r6			; r6 - Material data
		mov	r13,r5				; r5 - Go to UV section 
		add 	#polygn_srcpnts,r5
		mov	r7,r3				; r3 - copy of current face points (3 or 4)

	; New method
	rept 3
		mov.w	@r11+,r0			; Read UV index			
		extu	r0,r0
		shll2	r0
		mov	@(r6,r0),r0
		mov.w	r0,@(2,r5)
		shlr16	r0
		mov.w	r0,@r5
		add	#4,r5
	endm
		mov	#3,r0			; Triangle?
		cmp/eq	r0,r7
		bt	.alluvdone
		mov.w	@r11+,r0			; Read UV index			
		extu	r0,r0
		shll2	r0
		mov	@(r6,r0),r0
		mov.w	r0,@(2,r5)
		shlr16	r0
		mov.w	r0,@r5
.alluvdone:

		mov	r4,r0
		mov	#$1FFF,r5
		and	r5,r0
		shll2	r0
		shll	r0
		mov	@($10,r12),r6
		add	r0,r6
		mov	#$E000,r0		; grab special bits
		and	r0,r4
		shll16	r4
		mov	@(4,r6),r0
		or	r0,r4
		mov	r4,@(polygn_type,r13)
		mov	@r6,r0
		mov	r0,@(polygn_mtrl,r13)
		bra	.go_faces
		nop

; --------------------------------
; Set texture material
; --------------------------------

.solid_type:
		mov	r4,r0
		mov	#$E000,r5
		and	r5,r4
		shll16	r4
		mov	r4,@(polygn_type,r13)		; Set type 0 (tri) or quad (1)
		and	#$FF,r0
		mov	r0,@(polygn_mtrl,r13)		; Set pixel color (0-255)

; --------------------------------
; Read faces
; --------------------------------

.go_faces:
		mov	r13,r1
		add 	#polygn_points,r1
		mov	r11,r6
		mov	r7,r0
		shll	r0
		add	r0,r11
		mov 	r8,@-r15
		mov 	r9,@-r15
		mov 	r11,@-r15
		mov 	r12,@-r15
		mov 	r13,@-r15
		mov	#-160,r8
		neg	r8,r9
		mov	#-112,r11
		neg	r11,r12
		mov	#$7FFFFFFF,r5
		mov	#$FFFFFFFF,r13

	; New method, might speed up
	; a little...
	rept 3
		mov	#0,r0
		mov.w 	@r6+,r0
		mov	#$C,r4
		mulu	r4,r0
		sts	macl,r0
		mov	r10,r4
		add 	r0,r4
		mov	@r4,r2
		mov	@(4,r4),r3
		mov	@(8,r4),r4
		bsr	mdlrd_setpoint
		nop
		mov	r2,@r1
		mov	r3,@(4,r1)
		add	#8,r1
	endm
		mov	#3,r0			; Triangle?
		cmp/eq	r0,r7
		bt	.allfcsdone
		mov	#0,r0			; Do forth point for Quad
		mov.w 	@r6+,r0
		mov	#$C,r4
		mulu	r4,r0
		sts	macl,r0
		mov	r10,r4
		add 	r0,r4
		mov	@r4,r2
		mov	@(4,r4),r3
		mov	@(8,r4),r4
		bsr	mdlrd_setpoint
		nop
		mov	r2,@r1
		mov	r3,@(4,r1)
.allfcsdone:

		mov	r8,r1
		mov	r9,r2
		mov	r11,r3
		mov	r12,r4
		mov	r13,r6
		mov	@r15+,r13
		mov	@r15+,r12
		mov	@r15+,r11
		mov	@r15+,r9
		mov	@r15+,r8
		
	; NOTE: if you don't like how the perspective works
	; change this register depending how you want to ignore
	; faces closer to the camera:
	; 
	; r5 - Back Z point, keep affine limitations
	; r6 - Front Z point, skip face but larger faces are affected
		cmp/pz	r5
		bt	.face_out
		mov	#RAM_Mars_ObjCamera,r0
		mov	@(cam_y_pos,r0),r7
		shlr2	r7
		shlr2	r7
		shlr2	r7
		shlr	r7
		exts	r7,r7
		cmp/pl	r7
		bf	.revrscam
		neg	r7,r7
.revrscam:
		mov	#MAX_ZDIST,r0
		cmp/ge	r0,r7
		bt	.camlimit
		mov	r0,r7
.camlimit:
; 		cmp/pl	r6
; 		bt	.face_out
		mov	#MAX_ZDIST,r0		; Draw distance
		add 	r7,r0
		cmp/ge	r0,r5
		bf	.face_out
		
		mov	#-(SCREEN_WIDTH/2),r0
		cmp/gt	r0,r1
		bf	.face_out
		neg	r0,r0
		cmp/ge	r0,r2
		bt	.face_out
		mov	#-(SCREEN_HEIGHT/2),r0
		cmp/gt	r0,r3
		bf	.face_out
		neg	r0,r0
		cmp/ge	r0,r4
		bt	.face_out

; --------------------------------

.face_ok:
		mov.w	@(marsGbl_MdlFacesCntr,gbr),r0	; Add 1 face to the list
		add	#1,r0
		mov.w	r0,@(marsGbl_MdlFacesCntr,gbr)
		mov	r5,@r8				; Store current Z to Zlist
		mov	r13,@(4,r8)			; And it's address
		add	#8,r8
		add	#sizeof_polygn,r13
.face_out:
		dt	r9
		bt	.finish_this
		bra	.next_face
		nop
.finish_this:
		mov	r8,r0
		mov	r0,@(marsGbl_CurrZList,gbr)
		mov	r13,r0
		mov	r0,@(marsGbl_CurrFacePos,gbr)
.exit_model:
		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; ----------------------------------------	
; Modify position to current point
; ----------------------------------------

		align 4
mdlrd_setpoint:
		sts	pr,@-r15
		mov 	r5,@-r15
		mov 	r6,@-r15
		mov 	r7,@-r15
		mov 	r8,@-r15
		mov 	r9,@-r15
		mov 	r10,@-r15
		mov 	r11,@-r15
		
	; Object rotation
		mov	r2,r5			; r5 - X
		mov	r4,r6			; r6 - Z
  		mov 	@(mdl_x_rot,r14),r0
  		shlr2	r0
  		shlr	r0
  		bsr	mdlrd_rotate
		shlr8	r0
   		mov	r7,r2
   		mov	r3,r5
  		mov	r8,r6
  		mov 	@(mdl_y_rot,r14),r0
  		shlr2	r0
  		shlr	r0
  		bsr	mdlrd_rotate
		shlr8	r0
   		mov	r8,r4
   		mov	r2,r5
   		mov	r7,r6
   		mov 	@(mdl_z_rot,r14),r0
  		shlr2	r0
  		shlr	r0
  		bsr	mdlrd_rotate
		shlr8	r0
   		mov	r7,r2
   		mov	r8,r3
		mov	@(mdl_x_pos,r14),r5
		mov	@(mdl_y_pos,r14),r6
		mov	@(mdl_z_pos,r14),r7
		shlr8	r5
		shlr8	r6
		shlr8	r7
		exts	r5,r5
		exts	r6,r6		
		exts	r7,r7		
		add 	r5,r2
		add 	r6,r3
		add 	r7,r4

	; Include camera changes
		mov 	#RAM_Mars_ObjCamera,r11
		mov	@(cam_x_pos,r11),r5
		mov	@(cam_y_pos,r11),r6
		mov	@(cam_z_pos,r11),r7
		mov	@(mdl_data,r14),r0		; Layout object?
		shll	r0
		cmp/pl	r0
		bt	.lay_move
		mov	#$FFFFF,r0			; Limit camera movement
		and	r0,r5
; 		and	r0,r6
		and	r0,r7
.lay_move:
		shlr8	r5
		shlr8	r6
		shlr8	r7
		exts	r5,r5
		exts	r6,r6		
		exts	r7,r7
		sub 	r5,r2
		sub 	r6,r3
		add 	r7,r4

		mov	r2,r5
		mov	r4,r6
  		mov 	@(cam_x_rot,r11),r0
  		shlr2	r0
  		shlr	r0
  		bsr	mdlrd_rotate
		shlr8	r0
   		mov	r7,r2
   		mov	r8,r4
   		mov	r3,r5
  		mov	r8,r6
  		mov 	@(cam_y_rot,r11),r0
  		shlr2	r0
  		shlr	r0
  		bsr	mdlrd_rotate
		shlr8	r0
   		mov	r8,r4
   		mov	r2,r5
   		mov	r7,r6
   		mov 	@(cam_z_rot,r11),r0
  		shlr2	r0
  		shlr	r0
  		bsr	mdlrd_rotate
		shlr8	r0
   		mov	r7,r2
   		mov	r8,r3

	; Perspective projection
	; NOT PERFECT, this is the best I got.
		neg	r4,r0		; reverse Z
		cmp/pl	r0
		bt	.inside
		mov	#$1FFF,r6
		mov	@(cam_x_rot,r11),r5
		and	r6,r5
		shar	r5
		shar	r5
		shar	r5
		shar	r5		
		mov	r4,r0
		add 	#64,r0
		shll16	r0
		add	r4,r0
		add	r5,r0
		mov	r0,r5
		dmuls	r5,r2
		sts	mach,r0
		sts	macl,r2
		xtrct	r0,r2
		dmuls	r5,r3
		sts	mach,r0
		sts	macl,r3
		xtrct	r0,r3
	rept 3
		shar	r2
		shar	r3
	endm
		add	#-64,r4
		bra	.zmulti
		nop
.inside:
		mov	#512<<16,r7
		mov 	#_JR,r8
		add 	#64,r0
		mov 	r0,@r8
		mov 	r7,@(4,r8)
		nop
		mov 	@(4,r8),r7
		dmuls	r7,r2
		sts	mach,r0
		sts	macl,r2
		xtrct	r0,r2
		dmuls	r7,r3
		sts	mach,r0
		sts	macl,r3
		xtrct	r0,r3
.zmulti:

		mov	@r15+,r11
		mov	@r15+,r10
		mov	@r15+,r9
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r6
		mov	@r15+,r5
		
	; Set the most far limit points
	; for each direction (X,Y,Z)
		cmp/gt	r13,r4
		bf	.save_z2
		mov	r4,r13
.save_z2:
		cmp/gt	r5,r4
		bt	.save_z
		mov	r4,r5
.save_z:
		cmp/gt	r8,r2
		bf	.x_lw
		mov	r2,r8
.x_lw:
		cmp/gt	r9,r2
		bt	.x_rw
		mov	r2,r9
.x_rw:
		cmp/gt	r11,r3
		bf	.y_lw
		mov	r3,r11
.y_lw:
		cmp/gt	r12,r3
		bt	.y_rw
		mov	r3,r12
.y_rw:

		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; ------------------------------
; Rotate point
;
; Entry:
; r5: x
; r6: y
; r0: theta
;
; Returns:
; r7: (x  cos @) + (y sin @)
; r8: (x -sin @) + (y cos @)
; ------------------------------

mdlrd_rotate:
    		mov	#$7FF,r7
    		and	r7,r0
   		shll2	r0
		mov	#sin_table,r7
		mov	#sin_table+$800,r8
		mov	@(r0,r7),r9
		mov	@(r0,r8),r10

		dmuls	r5,r10		; x cos @
		sts	macl,r7
		sts	mach,r0
		xtrct	r0,r7
		dmuls	r6,r9		; y sin @
		sts	macl,r8
		sts	mach,r0
		xtrct	r0,r8
		add	r8,r7

		neg	r9,r9
		dmuls	r5,r9		; x -sin @
		sts	macl,r8
		sts	mach,r0
		xtrct	r0,r8
		dmuls	r6,r10		; y cos @
		sts	macl,r9
		sts	mach,r0
		xtrct	r0,r9
		add	r9,r8
 		rts
		nop
		align 4
	
; ------------------------------------------------
; MarsVideo_SetWatchdog
; 
; Starts interrupt for drawing the polygon pieces
; ------------------------------------------------

MarsVideo_SetWatchdog:
		stc	sr,@-r15
		stc	sr,r0
		or	#$F0,r0				; Disable interrupts first
		ldc	r0,sr
		mov	#RAM_Mars_VdpDrwList,r0		; Reset the piece-drawing pointer
		mov	r0,@(marsGbl_PlyPzList_R,gbr)	; on both READ and WRITE pointers
		mov	r0,@(marsGbl_PlyPzList_W,gbr)
		mov	#0,r0				; Reset polygon pieces counter
		mov.w	r0,@(marsGbl_PzListCntr,gbr)
		mov	#Cach_ClrLines,r1		; Line counter for the framebuffer-clear routine
		mov	#224,r0
		mov	r0,@r1
		mov	#8,r0				; Set starting watchdog task to $08 (Clear framebuffer)
		mov.w	r0,@(marsGbl_DrwTask,gbr)
		mov	#_vdpreg,r1
.wait_fb:
		mov.w	@($A,r1),r0			; Framebuffer available?
		tst	#2,r0
		bf	.wait_fb
		mov.w	#$A1,r0				; Pre-start SVDP fill line at address $A1
		mov.w	r0,@(6,r1)
		mov	#$FFFFFE80,r1
		mov.w	#$5AFF,r0			; Watchdog wait timer
		mov.w	r0,@r1
		mov.w	#$A538,r0			; Enable watchdog
		mov.w	r0,@r1
		ldc	@r15+,sr			; Restore interrupts
		rts
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Video CACHE routines for Master CPU
; ----------------------------------------------------------------

		align 4
CACHE_MASTER:
		phase $C0000000

; ------------------------------------------------
; MASTER Background tasks
; ------------------------------------------------

; Cache_OnInterrupt:
m_irq_custom:
		mov	#_FRT,r1
		mov.b	@(7,r1), r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov.w	@(marsGbl_DrwTask,gbr),r0	; Framebuffer clear request ($08)?
		cmp/eq	#8,r0
		bf	maindrw_tasks

; --------------------------------
; TASK $08 - Clear Framebuffer
; --------------------------------

; .task_08:
		mov	r2,@-r15
		mov	#_vdpreg,r1
		mov.b	@(marsGbl_CurrFb,gbr),r0
		mov	r0,r2
.wait_frmswp:	mov.b	@(framectl,r1),r0
		cmp/eq	r0,r2
		bf	.wait_frmswp
.wait_fb:	mov.w   @($A,r1), r0		; Framebuffer free?
		tst     #2,r0
		bf      .wait_fb
		mov.w   @(6,r1),r0		; SVDP-fill address
		add     #$5F,r0			; Preincrement
		mov.w   r0,@(6,r1)
		mov.w   #320/2,r0		; SVDP-fill size (320 pixels)
		mov.w   r0,@(4,r1)
		mov     #0,r0			; SVDP-fill pixel data and start filling
		mov.w   r0,@(8,r1)		; After finishing, SVDP-address got updated
		mov.l   #$FFFFFE80,r1
		mov.w   #$A518,r0		; OFF
		mov.w   r0,@r1
		or      #$20,r0			; ON
		mov.w   r0,@r1
		mov.w   #$5A10,r0
		mov.w   r0,@r1
		mov	#Cach_ClrLines,r1	; Decrement a line to progress
		mov	@r1,r0
		dt	r0
		bf/s	.on_clr
		mov	r0,@r1
		mov	#1,r0			; If finished: set task $01
		mov.w	r0,@(marsGbl_DrwTask,gbr)
.on_clr:
		mov	@r15+,r2
		rts
		nop
		align 4
		ltorg

; --------------------------------
; Main drawing routine
; --------------------------------

maindrw_tasks:
		shll2	r0
		mov	#.list,r1
		mov	@(r1,r0),r0
		jmp	@r0
		nop
		align 4
.list:
		dc.l drwtsk_01		; (null entry, but failsafe)
		dc.l drwtsk_01		; Main drawing routine
		dc.l drwtsk_02		; Resume from solid color

; --------------------------------
; Task $02
; --------------------------------

; TODO: currently it only resumes
; from solid_color

drwtsk_02:
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		mov	r5,@-r15
		mov	r6,@-r15
		mov	r7,@-r15
		mov	r8,@-r15
		mov	r9,@-r15
		mov	r10,@-r15
		mov	r11,@-r15
		mov	r12,@-r15
		mov	r13,@-r15
		mov	r14,@-r15
		sts	macl,@-r15
		sts	mach,@-r15
		mov	#Cach_LnDrw_L,r0
		mov	@r0+,r14
		mov	@r0+,r13
		mov	@r0+,r12
		mov	@r0+,r11
		mov	@r0+,r10
		mov	@r0+,r9
		mov	@r0+,r8
		mov	@r0+,r7
		mov	@r0+,r6
		mov	@r0+,r5
		mov	@r0+,r4
		mov	@r0+,r3
		mov	@r0+,r2
		mov	@r0+,r1
		mov	#1,r0
		mov.w	r0,@(marsGbl_DrwTask,gbr)
		bra	drwsld_updline
		nop

; --------------------------------
; Task $01
; --------------------------------

drwtsk_01:
		mov	r2,@-r15
		mov.w	@(marsGbl_PzListCntr,gbr),r0	; Any pieces to draw?
		cmp/eq	#0,r0
		bf	.has_pz
		mov	#0,r0				; If none, just end quickly.
		mov.w	r0,@(marsGbl_DrwTask,gbr)
		bra	drwtask_exit
		mov	#$7F,r2

.has_pz:
		mov	r3,@-r15
		mov	r4,@-r15
		mov	r5,@-r15
		mov	r6,@-r15
		mov	r7,@-r15
		mov	r8,@-r15
		mov	r9,@-r15
		mov	r10,@-r15
		mov	r11,@-r15
		mov	r12,@-r15
		mov	r13,@-r15
		mov	r14,@-r15
		sts	macl,@-r15
		sts	mach,@-r15
drwtsk1_newpz:
		mov	@(marsGbl_PlyPzList_R,gbr),r0	; r14 - Current pieces pointer to READ
		mov	r0,r14
		mov	@(plypz_ypos,r14),r9		; Start grabbing StartY/EndY positions
		mov	r9,r10
		mov	#$FFFF,r0
		shlr16	r9
		exts	r9,r9			;  r9 - Top
		and	r0,r10			; r10 - Bottom
		cmp/eq	r9,r0			; if Top==Bottom, exit
		bt	.invld_y
		mov	#SCREEN_HEIGHT,r0	; if Top > 224, skip
		cmp/ge	r0,r9
		bt	.invld_y		; if Bottom > 224, add max limit
		cmp/gt	r0,r10
		bf	.len_max
		mov	r0,r10
.len_max:
		sub	r9,r10			; r10: Turn it into Y lenght (Bottom - Top)
		cmp/pl	r10
		bt	drwtsk1_vld_y
.invld_y:
		bra	drwsld_nextpz		; if LEN < 0 then check next one instead.
		nop
		align 4
		ltorg

; ------------------------------------
; If Y top / Y len are valid:
; ------------------------------------

drwtsk1_vld_y:
		mov	@(plypz_xl,r14),r1		; r1 - X left
		mov	@(plypz_xl_dx,r14),r2		; r2 - DX left
		mov	@(plypz_xr,r14),r3		; r3 - X right
		mov	@(plypz_xr_dx,r14),r4		; r4 - DX right
		mov	@(plypz_mtrlopt,r14),r0		; Check material options
		shlr16	r0
		shlr8	r0
 		tst	#PLGN_TEXURE,r0			; Texture mode?
 		bf	drwtsk_texmode
		bra	drwtsk_solidmode
		nop

; ------------------------------------
; Texture mode
; 
; r1  - XL
; r2  - XL DX
; r3  - XR
; r4  - XR DX
; r5  - SRC XL
; r6  - SRC XR
; r7  - SRC YL
; r8  - SRC YR
; r9  - Y current
; r10  - Number of lines
; ------------------------------------

drwtsk_texmode:
		mov.w	@(marsGbl_DivReq_M,gbr),r0	; Waste interrupt if MarsVideo_MakePolygon is in the
		cmp/eq	#1,r0				; middle of division
		bf	.texvalid
		bra	drwtask_return
		nop
		align 4
.texvalid:
		mov	@(plypz_src_xl,r14),r5		; Texture X left
		mov	@(plypz_src_xr,r14),r6		; Texture X right
		mov	@(plypz_src_yl,r14),r7		; Texture Y up
		mov	@(plypz_src_yr,r14),r8		; Texture Y down

drwsld_nxtline_tex:
		cmp/pz	r9				; Y Line below 0?
		bf	drwsld_updline_tex
		mov	drwtex_tagshght,r0		; Y Line after 224?
		cmp/ge	r0,r9
		bt	drwtex_gonxtpz
		mov	r2,@-r15
		mov	r4,@-r15
		mov	r5,@-r15
		mov	r6,@-r15		
		mov	r7,@-r15
		mov	r8,@-r15
		mov	r10,@-r15
		mov	r13,@-r15
		mov	r1,r11			; r11 - X left copy
		mov	r3,r12			; r12 - X right copy
		shlr16	r11
		shlr16	r12
		exts	r11,r11
		exts	r12,r12
		mov	r12,r0			; r0: X Right - X Left
		sub	r11,r0
		cmp/pl	r0			; Line reversed?
		bt	.txrevers
		mov	r12,r0			; Swap XL and XR values
		mov	r11,r12
		mov	r0,r11
		mov	r5,r0
		mov	r6,r5
		mov	r0,r6
		mov	r7,r0
		mov	r8,r7
		mov	r0,r8
.txrevers:
		cmp/eq	r11,r12				; Same X position?
		bt	.tex_skip_line
		mov	#SCREEN_WIDTH,r0		; X right < 0?
		cmp/pl	r12
		bf	.tex_skip_line
		cmp/gt	r0,r11				; X left > 320?
		bt	.tex_skip_line
		mov	r12,r2
		mov 	r11,r0
		sub 	r0,r2
		sub	r5,r6
		sub	r7,r8

	; Calculate new DX values
		mov	#_JR,r0				; r6/r2
		mov	r2,@r0
		mov	r6,@(4,r0)
		nop
		mov	@(4,r0),r6			; r8/r2
		mov	r2,@r0
		mov	r8,@(4,r0)
		nop
		mov	@(4,r0),r8

	; Limit X destination points
	; and correct the texture's X positions
		mov	#SCREEN_WIDTH,r0		; XR point > 320?
		cmp/gt	r0,r12
		bf	.tr_fix
		mov	r0,r12				; Force XR to 320
.tr_fix:
		cmp/pl	r11				; XL point < 0?
		bt	.tl_fix
		neg	r11,r2				; Fix texture positions
		dmuls	r6,r2
		sts	macl,r0
		add	r0,r5
		dmuls	r8,r2
		sts	macl,r0
		add	r0,r7
		xor	r11,r11				; And reset XL to 0
.tl_fix:
		sub 	r11,r12
		cmp/pl	r12
		bf	.tex_skip_line
; 		mov	#$10,r0				; (Limiter test)
; 		cmp/ge	r0,r12
; 		bf	.testlwrit
; 		mov	r0,r12
; .testlwrit:
		mov 	r9,r0				; Y position * $200
		shll8	r0
		shll	r0
		mov 	#_overwrite+$200,r10		; Point to TOPLEFT in framebuffer
		add 	r0,r10				; Add Y
		add 	r11,r10				; Add X
		mov	#$1FFF,r2
		mov	@(plypz_mtrl,r14),r11		; r11 - texture data
		mov	@(plypz_mtrlopt,r14),r4		;  r4 - texture palincr|width
		mov	r4,r13
		shlr16	r4
		and	r2,r4
		mov	#$FF,r2
		and	r2,r13
.tex_xloop:
		mov	r7,r2
		shlr16	r2
		mulu	r2,r4
		mov	r5,r2	   			; Build column index
		sts	macl,r0
		shlr16	r2
		add	r2,r0
		mov.b	@(r0,r11),r0			; Read pixel
		add	r13,r0
		mov.b	r0,@r10	   			; Write pixel
		add 	#1,r10
		add	r6,r5				; Update X
		dt	r12
		bf/s	.tex_xloop
		add	r8,r7				; Update Y
.tex_skip_line:
		mov	@r15+,r13
		mov	@r15+,r10
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r6
		mov	@r15+,r5
		mov	@r15+,r4
		mov	@r15+,r2
drwsld_updline_tex:
		mov	@(plypz_src_xl_dx,r14),r0	; Update DX postions
		add	r0,r5
		mov	@(plypz_src_xr_dx,r14),r0
		add	r0,r6	
		mov	@(plypz_src_yl_dx,r14),r0
		add	r0,r7
		mov	@(plypz_src_yr_dx,r14),r0
		add	r0,r8
		add	r2,r1				; Update X postions
		add	r4,r3
		dt	r10
		bf/s	drwsld_nxtline_tex
		add	#1,r9
drwtex_gonxtpz:
		bra	drwsld_nextpz
		nop
		align 4
drwtex_tagshght	dc.l	SCREEN_HEIGHT

; ------------------------------------
; Solid Color
; ------------------------------------

drwtsk_solidmode:
		mov	#$FF,r0
		mov	@(plypz_mtrl,r14),r6
		mov	@(plypz_mtrlopt,r14),r5
		and	r0,r5
		and	r0,r6
		add	r5,r6
		mov	#_vdpreg,r13
drwsld_nxtline:
		mov	r9,r0
		add	r10,r0
		cmp/pl	r0
		bf	drwsld_nextpz
		cmp/pz	r9
		bf	drwsld_updline
		mov	#SCREEN_HEIGHT,r0
		cmp/gt	r0,r9
		bt	drwsld_nextpz
		mov	r1,r11
		mov	r3,r12
		shlr16	r11
		shlr16	r12
		exts	r11,r11
		exts	r12,r12
		mov	r12,r0
		sub	r11,r0
		cmp/pl	r0
		bt	.revers
		mov	r12,r0
		mov	r11,r12
		mov	r0,r11
.revers:
		mov	#SCREEN_WIDTH-1,r0
		cmp/pl	r12
		bf	drwsld_updline
		cmp/gt	r0,r11
		bt	drwsld_updline
		cmp/gt	r0,r12
		bf	.r_fix
		mov	r0,r12
.r_fix:
		cmp/pl	r11
		bt	.l_fix
		xor	r11,r11
.l_fix:
		mov	#-2,r0
		and	r0,r11
		and	r0,r12
		mov	r12,r0
		sub	r11,r0
; 		mov	#6,r5
; 		cmp/gt	r5,r0
; 		bf	drwsld_lowpixls
.wait:		mov.w	@(10,r13),r0
		tst	#2,r0
		bf	.wait
		mov	r12,r0
		sub	r11,r0
		shlr	r0
		mov.w	r0,@(4,r13)	; length
		mov	r11,r0
		shlr	r0
		mov	r9,r5
		add	#1,r5
		shll8	r5
		add	r5,r0
		mov.w	r0,@(6,r13)	; address
		mov	r6,r0
		shll8	r0
		or	r6,r0
		mov.w	r0,@(8,r13)	; Set data
		
	; If the line is large, leave it to VDP
	; and exit interrupt, we will come back
	; with more lines to draw
		mov	#$28,r0
		cmp/ge	r0,r12
		bf	drwsld_updline
		mov	#2,r0
		mov.w	r0,@(marsGbl_DrwTask,gbr)
		mov	#Cach_LnDrw_S,r0
		mov	r1,@-r0
		mov	r2,@-r0
		mov	r3,@-r0
		mov	r4,@-r0
		mov	r5,@-r0
		mov	r6,@-r0
		mov	r7,@-r0
		mov	r8,@-r0
		mov	r9,@-r0
		mov	r10,@-r0
		mov	r11,@-r0
		mov	r12,@-r0
		mov	r13,@-r0
		mov	r14,@-r0
		bra	drwtask_return
		mov	#0,r2
drwsld_updline:
		add	r2,r1
		add	r4,r3
		dt	r10
		bf/s	drwsld_nxtline
		add	#1,r9
		
; ------------------------------------
; if lower than 6 pixels
; (TODO: check this later)

; drwsld_lowpixls:
; 		cmp/pl	r0
; 		bf	drwsld_updline
; 		mov	r0,r12
; 		mov	r9,r0
; 		add	#1,r0
; 		shll8	r0
; 		shll	r0
; 		add 	r11,r0
; 		mov	#_overwrite+$200,r5
; 		add	r0,r5
; .wait_fb	mov.w	@(10,r13),r0
; 		tst	#2,r0
; 		bf	.wait_fb
; 		mov	#-1,r0
; .perpixl:
; 		mov.b	r0,@r5
; 		dt	r12
; 		bf/s	.perpixl
; 		add	#1,r5

; ------------------------------------		
		
drwsld_nextpz:
		mov.w	@(marsGbl_PzListCntr,gbr),r0	; -1 piece
		add	#-1,r0
		mov.w	r0,@(marsGbl_PzListCntr,gbr)
		add	#sizeof_plypz,r14		; Point to next piece for the next interrupt
		mov	r14,r0
		mov	#RAM_Mars_VdpDrwList_e,r14	; End-of-list?
		cmp/ge	r14,r0
		bf	.reset_rd
		mov	#RAM_Mars_VdpDrwList,r0
.reset_rd:
		mov	r0,@(marsGbl_PlyPzList_R,gbr)
; 		mov.w	@(marsGbl_PzListCntr,gbr),r0
; 		cmp/eq	#0,r0
; 		bt/s	.finish_it
; 		add	#-1,r0
; 		bra	drwtsk1_newpz
; 		mov.w	r0,@(marsGbl_PzListCntr,gbr)
.finish_it:
		bra	drwtask_return
		mov	#$10,r2

; --------------------------------
; Task $00
; --------------------------------

drwtsk_00:
		mov	r2,@-r15
		mov	#0,r0
		mov.w	r0,@(marsGbl_DrwTask,gbr)
		bra	drwtask_exit
		mov	#$7F,r2

drwtask_return:
		lds	@r15+,mach
		lds	@r15+,macl
		mov	@r15+,r14
		mov	@r15+,r13
		mov	@r15+,r12
		mov	@r15+,r11
		mov	@r15+,r10
		mov	@r15+,r9
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r6
		mov	@r15+,r5
		mov	@r15+,r4
		mov	@r15+,r3
drwtask_exit:
		mov.l   #$FFFFFE80,r1
		mov.w   #$A518,r0
		mov.w   r0,@r1
		or      #$20,r0
		mov.w   r0,@r1
		mov.w   #$5A00,r0
		or	r2,r0
		mov.w   r0,@r1
		mov	@r15+,r2
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------
; Read polygon and build pieces
; 
; Type bits:
; %tsp----- -------- -------- --------
; 
; p - Figure type: Quad (0) or Triangle (1)
; s - Polygon type: Normal (0) or Sprite (1)
; t - Polygon has texture data (1):
;     polygn_mtrlopt: Texture width
;     polygn_mtrl   : Texture data address
;     polygn_srcpnts: Texture X/Y positions for
;                     each edge (3 or 4)
; ------------------------------------------------

MarsVideo_MakePolygon:
		sts	pr,@-r15
		mov	#CachDDA_Top,r12
		mov	#CachDDA_Last,r13
		mov	@(polygn_type,r14),r0
		shlr16	r0
		shlr8	r0
		tst	#PLGN_TRI,r0			; PLGN_TRI set?
		bf	.tringl
		add	#8,r13
.tringl:
		mov	r14,r1
		mov	r12,r2
		mov	#CachDDA_Src,r3
		add	#polygn_points,r1
		tst	#PLGN_SPRITE,r0			; PLGN_SPRITE set?
		bt	.plgn_pnts
		
; ----------------------------------------
; Sprite points
; ----------------------------------------

; TODO: rework or get rid of this
.spr_pnts:
		mov.w	@r1+,r8		; X pos
		mov.w	@r1+,r9		; Y pos

		mov.w	@r1+,r4
		mov.w	@r1+,r6
		mov.w	@r1+,r5
		mov.w	@r1+,r7
		add	#2*2,r1
		add	r8,r4
		add 	r8,r5
		add	r9,r6
		add 	r9,r7
		mov	r5,@r2		; TR
		add	#4,r2
		mov	r6,@r2
		add	#4,r2
		mov	r4,@r2		; TL
		add	#4,r2
		mov	r6,@r2
		add	#4,r2
		mov	r4,@r2		; BL
		add	#4,r2
		mov	r7,@r2
		add	#4,r2
		mov	r5,@r2		; BR
		add	#4,r2
		mov	r7,@r2
		add	#4,r2

		mov.w	@r1+,r4
		mov.w	@r1+,r6
		mov.w	@r1+,r5
		mov.w	@r1+,r7
		mov	r5,@r3		; TR
		add	#4,r3
		mov	r6,@r3
		add	#4,r3
		mov	r4,@r3		; TL
		add	#4,r3
		mov	r6,@r3
		add	#4,r3
		mov	r4,@r3		; BL
		add	#4,r3
		mov	r7,@r3
		add	#4,r3
		mov	r5,@r3		; BR
		add	#4,r3
		mov	r7,@r3
		add	#4,r3
; 		mov	#4*2,r0
; .sprsrc_pnts:
; 		mov.w	@r1+,r0
; 		mov.w	@r1+,r4
; 		mov	r0,@r3
; 		mov	r4,@(4,r3)
; 		dt	r0
; 		bf/s	.sprsrc_pnts
; 		add	#8,r3
		bra	.start_math
		nop

; ----------------------------------------
; Polygon points
; ----------------------------------------

.plgn_pnts:
		mov	#4,r8
		mov	#SCREEN_WIDTH/2,r6
		mov	#SCREEN_HEIGHT/2,r7
.setpnts:
		mov	@r1+,r4
		mov	@r1+,r5
		add	r6,r4
		add	r7,r5
		mov	r4,@r2
		mov	r5,@(4,r2)
		dt	r8
		bf/s	.setpnts
		add	#8,r2
		mov	#4,r8
.src_pnts:
		mov.w	@r1+,r4
		mov.w	@r1+,r5
		mov	r4,@r3
		mov	r5,@(4,r3)
		dt	r8
		bf/s	.src_pnts
		add	#8,r3
		
.start_math:
		mov	#3,r9
		tst	#PLGN_TRI,r0			; PLGN_TRI set?
		bf	.ytringl
		add	#1,r9
.ytringl:
		mov	#$7FFFFFFF,r10
		mov	#$FFFFFFFF,r11
		mov 	r12,r7
		mov	r12,r8
.find_top:
		mov	@(4,r7),r0
		cmp/gt	r11,r0
		bf	.is_low
		mov 	r0,r11
.is_low:
		mov	@(4,r8),r0
		cmp/gt	r10,r0
		bt	.is_high
		mov 	r0,r10
		mov	r8,r1
.is_high:
		add 	#8,r7
		dt	r9
		bf/s	.find_top
		add	#8,r8
		cmp/ge	r11,r10			; Already reached end?
		bt	.exit
		cmp/pl	r11			; Bottom < 0?
		bf	.exit
		mov	#SCREEN_HEIGHT,r0	; Top > 224?
		cmp/ge	r0,r10
		bt	.exit
		
	; r1 - Main pointer
	; r2 - Left pointer
	; r3 - Right pointer
	; r4 - Left X
	; r5 - Left DX
	; r6 - Right X
	; r7 - Right DX
	; r8 - Left width
	; r9 - Right width
	; r10 - Top Y (gets updated after calling put_piece)
	; r11 - Bottom Y
	; r12 - First DST point
	; r13 - Last DST point
		mov	r1,r2				; r2 - X left to process
		mov	r1,r3				; r3 - X right to process
		bsr	set_left
		nop
		bsr	set_right
		nop
.next_pz:
		mov	#SCREEN_HEIGHT,r0		; Current Y > 224?
		cmp/gt	r0,r10
		bt	.exit
		cmp/ge	r11,r10				; Reached Y end?
		bt	.exit
		mov	@(marsGbl_PlyPzList_W,gbr),r0	; r1 - Current piece to WRITE
		mov	r0,r1
		mov	#RAM_Mars_VdpDrwList_e,r0	; pointer reached end of the list?
		cmp/ge	r0,r1
		bf	.dontreset
		mov	#RAM_Mars_VdpDrwList,r0		; Return WRITE pointer to the top of the list
		mov	r0,r1
		mov	r0,@(marsGbl_PlyPzList_W,gbr)
.dontreset:
		stc	sr,@-r15			; Stop interrupts (including Watchdog)
		stc	sr,r0
		or	#$F0,r0
		bsr	put_piece
		ldc	r0,sr
		ldc	@r15+,sr			; Restore interrupts
		cmp/gt	r9,r8				; Left width > Right width?
		bf	.lefth2
		bsr	set_right
		nop
		bra	.next_pz
		nop
.lefth2:
		bsr	set_left
		nop
		bra	.next_pz
		nop		
.exit:
		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; --------------------------------

set_left:
		mov	r2,r8			; Get a copy of Xleft pointer
		add	#$20,r8			; To read Texture SRC points
		mov	@r8,r4
		mov	@(4,r8),r5
		mov	#CachDDA_Src_L,r8
		mov	r4,r0
		shll16	r0
		mov	r0,@r8
		mov	r5,r0
		shll16	r0
		mov	r0,@(8,r8)
		mov	@r2,r1
		mov	@(4,r2),r8
		add	#8,r2
		cmp/gt	r13,r2
		bf	.lft_ok
		mov 	r12,r2
.lft_ok:
		mov	@(4,r2),r0
		sub	r8,r0
		cmp/eq	#0,r0
		bt	set_left
		cmp/pz	r0
		bf	.lft_skip

		lds	r0,mach
		mov	r2,r8
		add	#$20,r8
		mov 	@r8,r0
		sub 	r4,r0
		mov 	@(4,r8),r4
		sub 	r5,r4
		mov	r0,r5
		shll8	r4
		shll8	r5
		sts	mach,r8
		mov	#1,r0				; Stopsign for HW Division
		mov.w	r0,@(marsGbl_DivReq_M,gbr)
		mov	#_JR,r0				; HW DIV
		mov	r8,@r0
		mov	r5,@(4,r0)
		nop
		mov	@(4,r0),r5
		mov	#_JR,r0
		mov	r8,@r0
		mov	r4,@(4,r0)
		nop
		mov	@(4,r0),r4
		shll8	r4
		shll8	r5
		mov	#CachDDA_Src_L+$C,r0
		mov	r4,@r0
		mov	#CachDDA_Src_L+4,r0
		mov	r5,@r0
		mov	@r2,r5
		sub 	r1,r5
		mov 	r1,r4
		shll8	r5
		shll16	r4
		mov	#_JR,r0				; HW DIV
		mov	r8,@r0
		mov	r5,@(4,r0)
		nop
		mov	@(4,r0),r5
		mov	#0,r0				; Resume HW Division
		mov.w	r0,@(marsGbl_DivReq_M,gbr)
		shll8	r5
.lft_skip:
		rts
		nop
		align 4

; --------------------------------

set_right:
		mov	r3,r9
		add	#$20,r9
		mov	@r9,r6
		mov	@(4,r9),r7
		mov	#CachDDA_Src_R,r9
		mov	r6,r0
		shll16	r0
		mov	r0,@r9
		mov	r7,r0
		shll16	r0
		mov	r0,@(8,r9)

		mov	@r3,r1
		mov	@(4,r3),r9
		add	#-8,r3
		cmp/ge	r12,r3
		bt	.rgt_ok
		mov 	r13,r3
.rgt_ok:
		mov	@(4,r3),r0
		sub	r9,r0
		cmp/eq	#0,r0
		bt	set_right
		cmp/pz	r0
		bf	.rgt_skip
		lds	r0,mach
		mov	r3,r9
		add	#$20,r9
		mov 	@r9,r0
		sub 	r6,r0
		mov 	@(4,r9),r6
		sub 	r7,r6
		mov	r0,r7
		shll8	r6
		shll8	r7
		sts	mach,r9
		mov	#1,r0				; Resume HW Division
		mov.w	r0,@(marsGbl_DivReq_M,gbr)
		mov	#_JR,r0				; HW DIV
		mov	r9,@r0
		mov	r7,@(4,r0)
		nop
		mov	@(4,r0),r7
		mov	#_JR,r0
		mov	r9,@r0
		mov	r6,@(4,r0)
		nop
		mov	@(4,r0),r6
		shll8	r6
		shll8	r7
		mov	#CachDDA_Src_R+4,r0
		mov	r7,@r0
		mov	#CachDDA_Src_R+$C,r0
		mov	r6,@r0
		mov	@r3,r7
		sub 	r1,r7
		mov 	r1,r6
		shll16	r6
		shll8	r7
		mov	#_JR,r0				; HW DIV
		mov	r9,@r0
		mov	r7,@(4,r0)
		nop
		mov	@(4,r0),r7
		mov	#0,r0				; Resume HW Division
		mov.w	r0,@(marsGbl_DivReq_M,gbr)
		shll8	r7
.rgt_skip:
		rts
		nop
		align 4
		ltorg

; --------------------------------
; Mark piece
; --------------------------------

put_piece:
		mov	@(4,r2),r8
		mov	@(4,r3),r9
		sub	r10,r8
		sub	r10,r9
		mov	r8,r0
		cmp/gt	r8,r9
		bt	.lefth
		mov	r9,r0
.lefth:
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r5,@-r15
		mov	r7,@-r15
		mov	r8,@-r15
		mov	r9,@-r15
		mov 	r4,@(plypz_xl,r1)
		mov 	r5,@(plypz_xl_dx,r1)
		mov 	r6,@(plypz_xr,r1)
		mov 	r7,@(plypz_xr_dx,r1)
		dmuls	r0,r5
		sts	macl,r2
		dmuls	r0,r7
		sts	macl,r3
		add 	r2,r4
		add	r3,r6
		mov	r10,r2
		add	r0,r10
		mov	r10,r3
		shll16	r2
		or	r2,r3
		mov	r3,@(plypz_ypos,r1)
		mov	r3,@-r15
		mov	#CachDDA_Src_L,r2
		mov	@r2,r5
		mov	r5,@(plypz_src_xl,r1)
		mov	@(4,r2),r7
		mov	r7,@(plypz_src_xl_dx,r1)
		mov	@(8,r2),r8
		mov	r8,@(plypz_src_yl,r1)
		mov	@($C,r2),r9
		mov	r9,@(plypz_src_yl_dx,r1)
		dmuls	r0,r7
		sts	macl,r2
		dmuls	r0,r9
		sts	macl,r3
		add 	r2,r5
		add	r3,r8
		mov	#CachDDA_Src_L,r2
		mov	r5,@r2
		mov	r8,@(8,r2)
		mov	#CachDDA_Src_R,r2
		mov	@r2,r5
		mov	r5,@(plypz_src_xr,r1)
		mov	@(4,r2),r7
		mov	r7,@(plypz_src_xr_dx,r1)
		mov	@(8,r2),r8
		mov	r8,@(plypz_src_yr,r1)
		mov	@($C,r2),r9
		mov	r9,@(plypz_src_yr_dx,r1)
		dmuls	r0,r7
		sts	macl,r2
		dmuls	r0,r9
		sts	macl,r3
		add 	r2,r5
		add	r3,r8
		mov	#CachDDA_Src_R,r2
		mov	r5,@r2
		mov	r8,@(8,r2)
		mov	@r15+,r3
		cmp/pl	r3			; TOP check, 2 steps
		bt	.top_neg
		shll16	r3
		cmp/pl	r3
		bf	.bad_piece
.top_neg:
		mov	@(polygn_mtrl,r14),r0
		mov 	r0,@(plypz_mtrl,r1)
		mov	@(polygn_type,r14),r0
		mov 	r0,@(plypz_mtrlopt,r1)
		add	#sizeof_plypz,r1
		mov	r1,r0
		mov	#RAM_Mars_VdpDrwList_e,r8
		cmp/ge	r8,r0
		bf	.dontreset_pz
		mov	#RAM_Mars_VdpDrwList,r0
		mov	r0,r1
.dontreset_pz:
		mov	r0,@(marsGbl_PlyPzList_W,gbr)
		mov.w	@(marsGbl_PzListCntr,gbr),r0
		add	#1,r0
		mov.w	r0,@(marsGbl_PzListCntr,gbr)
.bad_piece:
		mov	@r15+,r9
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r5
		mov	@r15+,r3
		mov	@r15+,r2
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------

		align 4
Cach_LnDrw_L	ds.l 14			;
Cach_LnDrw_S	ds.l 0			; Reads backwards
CachDDA_Top	ds.l 2*2		; First 2 points
CachDDA_Last	ds.l 2*2		; Triangle or Quad (+8)
CachDDA_Src	ds.l 4*2
CachDDA_Src_L	ds.l 4			; X/DX/Y/DX result for textures
CachDDA_Src_R	ds.l 4
Cach_ClrLines	ds.l 1

; ------------------------------------------------
.end:		phase CACHE_MASTER+.end&$1FFF
CACHE_MASTER_E:
		align 4

; ====================================================================
; ----------------------------------------------------------------
; Video CACHE routines for Slave CPU
; ----------------------------------------------------------------

		align 4
CACHE_SLAVE:
		phase $C0000000
; ------------------------------------------------
		dc.b "SLAVE CACHE CODE GOES HERE"
; ------------------------------------------------
.end:		phase CACHE_SLAVE+.end&$1FFF
CACHE_SLAVE_E:
		align 4
