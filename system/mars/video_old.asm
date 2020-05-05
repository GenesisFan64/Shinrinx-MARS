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

MAX_FACES		equ	256
MAX_SVDP_PZ		equ	1024
MAX_MODELS		equ	64
MAX_DIVTABLE		equ	$800		; LONGS
MAX_PERSP		equ	$4000 		; WORDS

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
; 		struct 0		; MOVED to system/const.asm (shared with MD)
; mdl_data	ds.l 1
; mdl_x_pos	ds.l 1
; mdl_y_pos	ds.l 1
; mdl_z_pos	ds.l 1
; mdl_x_rot	ds.l 1
; mdl_y_rot	ds.l 1
; mdl_z_rot	ds.l 1
; sizeof_mdlobj	ds.l 0
; 		finish

; OUTPUT polygon piece data
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
polygn_type	ds.l 1		; %MSTo oooo oooo oooo | Type bits and Material option (Width or PalIncr)
polygn_mtrl	ds.l 1		; Material Type: Color (0-255) or Texture data address
polygn_points	ds.l 4		; X/Y positions
polygn_srcpnts	ds.l 4		; X/Y texture points (16-bit), blank if using solidcolor
sizeof_polygn	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; Init Video
; 
; Uses:
; a0-a2,d0-d1
; ----------------------------------------------------------------

MarsVideo_Init:
		sts	pr,@-r15
		mov	#_sysreg,r4
		mov 	#FM,r0			; FB to MARS
  		mov.b	r0,@(adapter,r4)
		mov 	#_vdpreg,r4
		bsr	.this_fb		; Init line table(s) and swap
		nop
		bsr	.this_fb
		nop
		mov	#1,r0			; Enable bitmap $01
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
		mov	#$200/2,r0		; START line data
		mov	#240,r2			; Vertical lines to set
		mov	r0,r3			; Increment value (copy from r0)
.loop:
		mov.w	r0,@r1
		add	#2,r1
		add	r3,r0
		dt	r2
		bf	.loop
		
.fb_wait1:	mov.w   @($A,r4),r0
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
; Generate division table
; it's faster than doing on HW
; everytime
; 
; r1 - x/?
; r2 - Output
; 
; zero division will be a
; copy of ??/1
; 
; Example:
; 	mov	#RAM_YourDivTable,r0
; 	mov	@(r0,r2),r0	; (??/xx) << 2
; 	dmuls	r6,r0		; (xx/r0)
; 	sts	macl,r6
; 	sts	mach,r0
; 	xtrct   r0,r6		; Result
; ------------------------------------

Mars_MkDivTable:
		mov	#$FFFFFF00,r6
		mov	#MAX_DIVTABLE,r4
		mov     #0,r5
		shll16  r1
.loop:
		mov	r5,r0
		cmp/eq	#0,r0
		bf	.dontzer
		mov	#1,r0
.dontzer:
		mov	r5,@r6
		mov	r1,@(4,r6)
		nop
		mov	@(4,r6),r0
		mov	r0,@r2
		add     #4,r2
		add     #1,r5
		dt      r4
		bf	.loop
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
		mov.l	#$20004100,r2
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
; Load palette to RAM, the
; Palette will be transfered on VBlank
;
; Input:
; r1 - Data
; r2 - Start at
; r3 - Number of colors
; 
; Uses:
; r0,r4-r6
; ------------------------------------

MarsVideo_LoadPal:
		mov 	r1,r4
		mov 	#RAM_Mars_Palette,r5
		mov 	r2,r0
		shll	r0
		add 	r0,r5
		mov 	r3,r6
.loop:
		mov.w	@r4+,r0
		mov.w	r0,@r5
		add 	#2,r5
		dt	r6
		bf	.loop
		rts
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; 3D MODEL RENDER
; ----------------------------------------------------------------

MarsMdl_Init:
		sts	pr,@-r15
		mov	#RAM_Mars_DivTable,r2
		bsr	Mars_MkDivTable
		mov	#1,r1
		mov	#_JR,r5
		mov	#RAM_Mars_PerspTable,r2
		mov	#$E000,r1
		mov	#0,r0
		mov.w	r0,@r2
		add	#2,r2
		mov	#MAX_PERSP-1,r3
		mov	#1,r4
.next:
		mov.l	r4,@r5
		mov.l	r1,@(4,r5)
		nop
		mov.l	@(4,r5),r0
		mov.w	r0,@r2
		add	#2,r2
		dt	r3
		bf/s	.next
		add	#1,r4
		mov	#0,r0
		mov	#RAM_Mars_Objects,r1
		mov	#sizeof_mdlobj/4,r2
.clnup:
		mov	r0,@r1
		dt	r2
		bf/s	.clnup
		add	#4,r1
		
		lds	@r15+,pr
		rts
		nop
		align 4

; ------------------------------------------------
; MarsMdl_MakeModel
; 
; r14 - Current model address
; ------------------------------------------------

MarsMdl_MakeModel:
		sts	pr,@-r15
		mov	@(marsGbl_CurrFacePos,gbr),r0
		mov	r0,r13				; r13 - output faces
		mov	@(mdl_data,r14),r12
		mov 	@(8,r12),r11			; r11 - face data
		mov 	@(4,r12),r10			; r10 - vertice data (X,Y,Z)
		mov.w	@r12,r9				; r9 - numof_faces in model
		mov	@(marsGbl_CurrZList,gbr),r0
		mov	r0,r8
.next_face:
		mov.w	@(marsGbl_MdlFacesCntr,gbr),r0
		mov	#MAX_FACES,r1
		cmp/ge	r1,r0
		bf	.go_build
		bra	.exit_model
		nop
.go_build:
		mov.w	@r11+,r4
		mov	#3,r7
		mov	r4,r0
		shlr8	r0
		tst	#PLGN_TRI,r0
		bf	.set_tri
		add	#1,r7
.set_tri:
		cmp/pl	r4
		bt	.solid_type

; --------------------------------
; Set texture material
; --------------------------------

		mov	@($C,r12),r6		; r6 - material vertex
		mov	r13,r5
		add 	#polygn_srcpnts,r5	; r5 - Output SRC points
		mov	r7,r3
.srctri:
		mov.w	@r11+,r0
		shll2	r0
		mov	@(r6,r0),r0
		mov.w	r0,@(2,r5)
		shlr16	r0
		mov.w	r0,@r5
		dt	r3
		bf/s	.srctri
		add	#4,r5

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
		mov	r4,@(polygn_type,r13)
		and	#$FF,r0
		mov	r0,@(polygn_mtrl,r13)

; --------------------------------
; Do faces
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
		mov	#-160,r8
		neg	r8,r9
		mov	#-112,r11
		neg	r11,r12
		mov	#$7FFFFFFF,r5
.vert_loop:
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
		bsr	mdlrd_setpersp
		nop
		cmp/ge	r5,r4
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
; 		mov	#_sysreg+comm0,r0
; 		mov.w	r12,@r0
.y_rw:		
		mov.w	r2,@r1
		mov	r3,r0
		mov.w	r0,@(2,r1)
		dt	r7
		bf/s	.vert_loop
		add	#4,r1

		mov	r8,r1
		mov	r9,r2
		mov	r11,r3
		mov	r12,r4
		mov	@r15+,r12
		mov	@r15+,r11
		mov	@r15+,r9
		mov	@r15+,r8
		cmp/pl	r5
		bt	.face_out
		mov	#RAM_Mars_ObjCamera,r6
		mov	@(cam_y_pos,r6),r7
		shlr8	r7
		exts	r7,r7
		cmp/pl	r7
		bf	.revrscam
		neg	r7,r7
.revrscam:
		mov	#-$400,r0
		cmp/ge	r0,r7
		bt	.camlimit
		mov	r0,r7
.camlimit:
		mov	#-$600,r0	; Draw distance
		add 	r7,r0
		cmp/ge	r0,r5
		bf	.face_out
		mov	#-160,r0
		cmp/gt	r0,r1
		bf	.face_out
		neg	r0,r0
		cmp/ge	r0,r2
		bt	.face_out
		mov	#-112,r0
		cmp/gt	r0,r3
		bf	.face_out
		neg	r0,r0
		cmp/ge	r0,r4
		bt	.face_out

; --------------------------------

.face_ok:
		mov.w	@(marsGbl_MdlFacesCntr,gbr),r0
		add	#1,r0
		mov.w	r0,@(marsGbl_MdlFacesCntr,gbr)
		mov	r5,@r8
		add	#4,r8
		mov	r13,@r8
		add	#4,r8
		add	#sizeof_polygn,r13
.face_out:
		dt	r9
		bt	.finish_this
		bra	.next_face
		nop
.finish_this:
		mov	r8,r0
		mov	r0,@(marsGbl_CurrZList,gbr)
.exit_model:
		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; ----------------------------------------	
; Perspective X/Y/Z
; ----------------------------------------

mdlrd_setpersp:
		sts	pr,@-r15
		mov 	r5,@-r15
		mov 	r6,@-r15
		mov 	r7,@-r15
		mov 	r8,@-r15
		mov 	r9,@-r15
		mov 	r10,@-r15
		
; 	; PASS 1
		mov	@(mdl_x_rot,r14),r0	; X rotation
; 		shlr	r0
		bsr	mdlrd_readsine
		shlr8	r0
		dmuls	r2,r8			; X cos @
		sts	macl,r5
		sts	mach,r0
		xtrct	r0,r5
		dmuls	r4,r7			; Z sin @
		sts	macl,r6
		sts	mach,r0
		xtrct	r0,r6
		add 	r6,r5
		neg	r7,r7
		dmuls	r2,r7			; X -sin @
		sts	macl,r6
		sts	mach,r0
		xtrct	r0,r6
		dmuls	r4,r8			; Z cos @
		sts	macl,r0
		sts	mach,r7
		xtrct	r7,r0
		add	r0,r6
		mov 	r5,r2			; Save X	
		mov	@(mdl_y_rot,r14),r0	; Y rotation
; 		shlr	r0
		bsr	mdlrd_readsine
		shlr8	r0		
		mov	r3,r9
		dmuls	r3,r8			; Y cos @
		sts	macl,r9
		sts	mach,r0
		xtrct	r0,r9
		dmuls	r6,r7			; Z sin @
		sts	macl,r5
		sts	mach,r0
		xtrct	r0,r5
		add 	r5,r9
		neg	r7,r7
		dmuls	r3,r7			; Y -sin @
		mov	r9,r3			; Save Y
		sts	macl,r9
		sts	mach,r0
		xtrct	r0,r9
		dmuls	r6,r8			; Z cos @
		sts	macl,r5
		sts	mach,r0
		xtrct	r0,r5
		add	r5,r9
		mov	r9,r4			; Save Z
		mov	@(mdl_z_rot,r14),r0	; Z rotation
; 		shlr	r0
		bsr	mdlrd_readsine
		shlr8	r0
		add 	r7,r0
		dmuls	r2,r8			; X cos @
		sts	macl,r5
		sts	mach,r0
		xtrct	r0,r5
		dmuls	r3,r7			; Z sin @
		sts	macl,r6
		sts	mach,r0
		xtrct	r0,r6
		add 	r6,r5
		neg	r7,r7
		dmuls	r2,r7			; X -sin @
		sts	macl,r6
		sts	mach,r0
		xtrct	r0,r6
		dmuls	r3,r8			; Z cos @
		sts	macl,r0
		sts	mach,r7
		xtrct	r7,r0
		add	r0,r6
		mov 	r5,r2			; Save X
		mov	r6,r3
		mov	@(mdl_x_pos,r14),r0
		shlr8	r0
		exts	r0,r0
		add 	r0,r2
		mov	@(mdl_y_pos,r14),r0
		shlr8	r0
		exts	r0,r0
		add 	r0,r3
		mov	@(mdl_z_pos,r14),r0
		shlr8	r0
		exts	r0,r0
		add 	r0,r4


		mov 	#RAM_Mars_ObjCamera,r10
		mov	@(cam_x_pos,r10),r0
		shlr8	r0
		exts	r0,r0
		sub 	r0,r2
		mov	@(cam_y_pos,r10),r0
		shlr8	r0
		exts	r0,r0
		sub 	r0,r3
		mov	@(cam_z_pos,r10),r0
		shlr8	r0
		exts	r0,r0
		add 	r0,r4
		mov	@(cam_x_rot,r10),r0	; X rotation
		bsr	mdlrd_readsine
		shlr8	r0
		dmuls	r2,r8		; X cos @
		sts	macl,r5
		sts	mach,r0
		xtrct	r0,r5
		dmuls	r4,r7		; Z sin @
		sts	macl,r6
		sts	mach,r0
		xtrct	r0,r6
		add 	r6,r5
		neg	r7,r7
		dmuls	r2,r7		; X -sin @
		sts	macl,r6
		sts	mach,r0
		xtrct	r0,r6
		dmuls	r4,r8		; Z cos @
		sts	macl,r0
		sts	mach,r7
		xtrct	r7,r0
		add	r0,r6
		mov 	r5,r2		; Save X	
		mov	@(cam_y_rot,r10),r0	; Y rotation
		bsr	mdlrd_readsine
		shlr8	r0
		mov	r3,r9
		dmuls	r3,r8		; Y cos @
		sts	macl,r9
		sts	mach,r0
		xtrct	r0,r9
		dmuls	r6,r7		; Z sin @
		sts	macl,r5
		sts	mach,r0
		xtrct	r0,r5
		add 	r5,r9
		neg	r7,r7
		dmuls	r3,r7		; Y -sin @
		mov	r9,r3		; Save Y
		sts	macl,r9
		sts	mach,r0
		xtrct	r0,r9
		dmuls	r6,r8		; Z cos @
		sts	macl,r5
		sts	mach,r0
		xtrct	r0,r5
		add	r5,r9
		mov	r9,r4		; Save Z
		mov	@(cam_z_rot,r10),r0	; Z rotation
		bsr	mdlrd_readsine
		shlr8	r0
		add 	r7,r0
		dmuls	r2,r8		; X cos @
		sts	macl,r5
		sts	mach,r0
		xtrct	r0,r5
		dmuls	r3,r7		; Z sin @
		sts	macl,r6
		sts	mach,r0
		xtrct	r0,r6
		add 	r6,r5
		neg	r7,r7
		dmuls	r2,r7		; X -sin @
		sts	macl,r6
		sts	mach,r0
		xtrct	r0,r6
		dmuls	r3,r8		; Z cos @
		sts	macl,r0
		sts	mach,r7
		xtrct	r7,r0
		add	r0,r6
		mov 	r5,r2		; Save X

		cmp/pl	r4
		bf	.inside
		mov	#1,r0
		bra	.offscrn
		nop
.inside:
		neg	r4,r0
.offscrn:
		mov	#60,r7		; this is the only
		cmp/ge	r7,r0		; fix i got
		bt	.notzer
		mov	r7,r0
.notzer:
		mov	#MAX_PERSP,r8
		cmp/gt	r8,r0
		bf	.toomuch
		mov	r8,r0
.toomuch:
		mov	#RAM_Mars_PerspTable,r8
		shll	r0
		mov.w	@(r8,r0),r8
		extu.w	r8,r8
		muls	r8,r2
		sts	macl,r2
		muls	r8,r3
		sts	macl,r3
.lel:
		shlr8	r2
		shlr8	r3
		exts	r2,r2
		exts	r3,r3

		mov	@r15+,r10
		mov	@r15+,r9
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r6
		mov	@r15+,r5
		lds	@r15+,pr
		rts
		nop
		align 4


; 		mov	#$F0,r8
; 		bra	*
; 		ldc	r8,sr
; 
; 		dmuls	r2,r8
; 		sts	macl,r2
; 		sts	mach,r0
; 		xtrct   r0,r2
; 		dmuls	r3,r8
; 		sts	macl,r3
; 		sts	mach,r0
; 		xtrct   r0,r3
; .no_div:

; 		mov	r4,r0			; Kinda working
; 		cmp/pz	r0
; 		bt	.lel
; 		neg 	r0,r0
; .dontneg:
; 		mov	#MAX_DIVTABLE,r8
; 		cmp/gt	r8,r0
; 		bf	.toomuch
; 		mov	r8,r0
; .toomuch:
; 		shll2	r0		
; 		mov	#RAM_Mars_DivTable,r8
; 		mov	@(r8,r0),r8
; 		shll8	r8
; 		dmuls	r2,r8
; 		sts	macl,r2
; 		sts	mach,r0
; 		xtrct   r0,r2
; 		dmuls	r3,r8
; 		sts	macl,r3
; 		sts	mach,r0
; 		xtrct   r0,r3
; .lel:

; ------------------------------------------------
; Input:
; r0 - tan
; 
; Output:
; r7 - sin
; r8 - cos
; ------------------------------------------------

mdlrd_readsine:
		shll2	r0
		mov	#$1FFF,r7
		and	r7,r0
		mov	#sin_table,r7
		mov	#sin_table+$800,r8
		mov	@(r0,r7),r7
		mov	@(r0,r8),r8
		rts
		nop
		align 4

; ----------------------------------------

		ltorg

; ------------------------------------------------
; MarsRndr_SetWatchdog
; 
; Start interrupt for drawing the polygons
; pieces
; ------------------------------------------------

MarsRndr_SetWatchdog:
		stc.l	sr,@-r15
		stc	sr,r0
		or	#$F0,r0
		ldc	r0,sr
		mov.l	#$20004100,r1
.wait_fb:
		mov.w	@($A,r1), r0
		tst	#2,r0
		bf	.wait_fb
		mov.w	#$A1,r0				; Start at 161
		mov.w	r0,@(6,r1)
		mov	#0,r0
		mov.w	r0,@(marsGbl_VdpListCnt,gbr)
		mov	#Cach_ClrLines,r1
		mov	#$E0,r0
		mov.w	r0,@r1
		mov	#8,r0
		mov.w	r0,@(marsGbl_DrwTask,gbr)
		mov	#RAM_Mars_VdpDrwList,r0
		mov	r0,@(marsGbl_VdpList_R,gbr)
		mov	r0,@(marsGbl_VdpList_W,gbr)

		mov.l	#$FFFFFE80,r1
		mov.w	#$5AFF,r0
		mov.w	r0,@r1
		mov.w	#$A538,r0
		mov.w	r0,@r1
		ldc.l	@r15+,sr
		rts
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Video CACHE routines
; ----------------------------------------------------------------

		align 4
CACHE_START:
		phase $C0000000

; ------------------------------------------------
; MASTER Background tasks
; ------------------------------------------------

m_irq_custom:
		mov.l   r2,@-r15
		mov.l   #$FFFFFE10,r1
		mov.b   @(7,r1), r0
		xor     #2,r0
		mov.b   r0,@(7,r1)
		mov.w	@(marsGbl_DrwTask,gbr),r0
		cmp/eq	#8,r0
		bf	maindrw_tasks

; --------------------------------
; TASK $01 - Clear Framebuffer
; --------------------------------

.task_01:
		mov.l   #$20004100,r2
.wait_fb:
		mov.w   @($A,r2), r0
		tst     #2,r0
		bf      .wait_fb
		mov.w   @(6,r2),r0
		add     #$5F,r0		; Preincrement
		mov.w   r0,@(6,r2)
		mov.w   #$A0,r0
		mov.w   r0,@(4,r2)
		mov     #0,r0
		mov.w   r0,@(8,r2)
		mov.l   #$FFFFFE80,r2
		mov.w   #$A518,r0	; OFF
		mov.w   r0,@r2
		or      #$20,r0		; ON
		mov.w   r0,@r2
		mov.w   #$5A10,r0
		mov.w   r0,@r2
		mov	#Cach_ClrLines,r1
		mov.w	@r1,r0
		dt	r0
		bf/s	.on_clr
		mov.w	r0,@r1
		mov	#1,r0
		mov.w	r0,@(marsGbl_DrwTask,gbr)
.on_clr:
		mov.l   @r15+,r2
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

; --------------------------------

.list:
		dc.l drwtsk_01		; 
		dc.l drwtsk_01		; Main drawing routine
		dc.l drwtsk_02		; Resume from solid color
		
; --------------------------------
; Task $00
; --------------------------------

drwtsk_00:
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

; --------------------------------
; Task $02
; --------------------------------

drwtsk_02:
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
		mov	@r0+,r10
		mov	@r0+,r9
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
		mov.w	@(marsGbl_VdpListCnt,gbr),r0
		cmp/eq	#0,r0
		bf/s	.has_pz
		add	#-1,r0
		mov	#0,r0
		mov.w	r0,@(marsGbl_DrwTask,gbr)
		bra	drwtask_exit
		mov	#$7F,r2
.has_pz	
		mov.w	r0,@(marsGbl_VdpListCnt,gbr)
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
		mov	@(marsGbl_VdpList_R,gbr),r0
		mov	r0,r14
		mov	@(plypz_ypos,r14),r9
		mov	r9,r10
		mov	#$FFFF,r0
		shlr16	r9
		exts	r9,r9
		and	r0,r10
		cmp/eq	r9,r0
		bt	.invld_y
		mov	#SCREEN_HEIGHT,r0
		cmp/ge	r0,r9
		bt	.invld_y
		cmp/gt	r0,r10
		bf	.len_max
		mov	r0,r10
.len_max:
		sub	r9,r10
		cmp/pl	r10
		bt	drwtsk1_vld_y
.invld_y:
		bra	drwsld_nextpz
		nop
		align 4
		ltorg

; ------------------------------------

drwtsk1_vld_y:
		mov	@(plypz_xl,r14),r1
		mov	@(plypz_xl_dx,r14),r2
		mov	@(plypz_xr,r14),r3
		mov	@(plypz_xr_dx,r14),r4
		mov	@(plypz_mtrlopt,r14),r0
		shlr16	r0
		shlr8	r0
 		tst	#PLGN_TEXURE,r0
 		bt	.solid_color
		
; ------------------------------------
; Texture
; r1  - XL
; r2  - XL DX
; r3  - XR
; r4  - XR DX
; r5  - SRC XL
; r6  - SRC XR
; r7  - SRC YL
; r8  - SRC YR
; r9  - Y current
; r10  - Y end
; ------------------------------------

		mov	@(plypz_src_xl,r14),r5
		mov	@(plypz_src_xr,r14),r6
		mov	@(plypz_src_yl,r14),r7
		mov	@(plypz_src_yr,r14),r8
.tex_next_line:
		cmp/pl	r9
		bf	.tex_skip_line
		mov	#SCREEN_HEIGHT,r0
		cmp/ge	r0,r9
		bt	.tex_skip_line

		mov	r2,@-r15
		mov	r4,@-r15
		mov	r5,@-r15
		mov	r6,@-r15		
		mov	r7,@-r15
		mov	r8,@-r15
		mov	r10,@-r15
		mov	r1,r11
		mov	r3,r12
		shlr16	r11
		shlr16	r12
		exts	r11,r11
		exts	r12,r12
		mov	r12,r0
		sub	r11,r0
		cmp/pl	r0
		bt	.txrevers
		mov	r12,r0
		mov	r11,r12
		mov	r0,r11
		mov	r5,r0
		mov	r6,r5
		mov	r0,r6
		mov	r7,r0
		mov	r8,r7
		mov	r0,r8
.txrevers:
		cmp/eq	r11,r12
		bt	.tex_upd_line
		mov	#SCREEN_WIDTH,r0
		cmp/pl	r12
		bf	.tex_upd_line
		cmp/gt	r0,r11
		bt	.tex_upd_line
		mov	r12,r2
		mov 	r11,r0
		sub 	r0,r2
		sub	r5,r6
		sub	r7,r8

		shll2	r2
		mov	#RAM_Mars_DivTable,r0
		mov	@(r0,r2),r0
		dmuls	r6,r0
		sts	macl,r6
		sts	mach,r0
		xtrct   r0,r6
		mov	#RAM_Mars_DivTable,r0
		mov	@(r0,r2),r0
		dmuls	r8,r0
		sts	macl,r8
		sts	mach,r0
		xtrct   r0,r8
		mov	#SCREEN_WIDTH,r0
		cmp/gt	r0,r12
		bf	.tr_fix
		mov	r0,r12
.tr_fix:
		cmp/pl	r11
		bt	.tl_fix
		neg	r11,r2
		dmuls	r6,r2
		sts	macl,r0
		add	r0,r5
		dmuls	r8,r2
		sts	macl,r0
		add	r0,r7
		xor	r11,r11
.tl_fix:
		mov 	r9,r0
		shll8	r0
		shll	r0
		sub 	r11,r12
		cmp/pl	r12
		bf	.tex_upd_line
		mov 	#_overwrite+$200,r10
		add 	r0,r10
		add 	r11,r10
		mov	@(plypz_mtrl,r14),r11		; texture data
		mov	@(plypz_mtrlopt,r14),r4		; texture width
.texloop:
		mov	r7,r2
		shlr16	r2
		mulu	r2,r4
		mov	r5,r2	   			; Build column index
		sts	macl,r0
		shlr16	r2
		add	r2,r0
		mov.b	@(r0,r11),r0			; Read pixel
		mov.b	r0,@r10	   			; Write pixel
		add 	#1,r10
		add	r6,r5				; Update X
		dt	r12
		bf/s	.texloop
		add	r8,r7				; Update Y
.tex_upd_line:
		mov	@r15+,r10
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r6
		mov	@r15+,r5
		mov	@r15+,r4
		mov	@r15+,r2
.tex_skip_line:
		mov	@(plypz_src_xl_dx,r14),r0
		add	r0,r5
		mov	@(plypz_src_xr_dx,r14),r0
		add	r0,r6	
		mov	@(plypz_src_yl_dx,r14),r0
		add	r0,r7
		mov	@(plypz_src_yr_dx,r14),r0
		add	r0,r8
		add	r2,r1
		add	r4,r3
		dt	r10
		bf/s	.tex_next_line
		add	#1,r9
		bra	drwsld_nextpz
		nop

; ------------------------------------
; Solid Color
; ------------------------------------

.solid_color:
		mov	#$FF,r0
		mov	@(plypz_mtrl,r14),r6
		mov	@(plypz_mtrlopt,r14),r5
		and	r0,r5
		and	r0,r6
		add	r5,r6
		mov	#_vdpreg,r13
drwsld_nxtline:
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
		mov	#SCREEN_WIDTH,r0
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
		mov	#$28,r0		; line too large
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
		mov	r9,@-r0
		mov	r10,@-r0		
		mov	r13,@-r0
		mov	r14,@-r0
		bra	drwtask_return
		mov	#0,r2

; 		bra	drwsld_updline
; 		nop

; ------------------------------------
; if lower than 6 pixels

drwsld_lowpixls:
		cmp/pl	r0
		bf	drwsld_updline
		mov	r0,r12
		mov	r9,r0
		add	#1,r0
		shll8	r0
		shll	r0
		add 	r11,r0
		mov	#_overwrite+$200,r5
		add	r0,r5
.wait_fb	mov.w	@(10,r13),r0
		tst	#2,r0
		bf	.wait_fb
		mov	#-1,r0
.perpixl:
		mov.b	r0,@r5
		dt	r12
		bf/s	.perpixl
		add	#1,r5
		
; ------------------------------------

drwsld_updline:
		add	r2,r1
		add	r4,r3
		dt	r10
		bf/s	drwsld_nxtline
		add	#1,r9
drwsld_nextpz:
		add	#sizeof_plypz,r14
		mov	r14,r0
		mov	r0,@(marsGbl_VdpList_R,gbr)
; 		mov.w	@(marsGbl_VdpListCnt,gbr),r0
; 		cmp/eq	#0,r0
; 		bt/s	.finish_it
; 		add	#-1,r0
; 		bra	drwtsk1_newpz
; 		mov.w	r0,@(marsGbl_VdpListCnt,gbr)
.finish_it:
		bra	drwtask_return
		mov	#$10,r2
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

; TODO: rework on this
; it sucks

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
		mov.w	@r1+,r4
		mov.w	@r1+,r5
		exts	r4,r4
		exts	r5,r5
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
		cmp/eq	r11,r10
		bt	.exit

		cmp/pl	r11
		bf	.exit
		mov	#SCREEN_HEIGHT+1,r0
		cmp/gt	r0,r10
		bt	.exit

	; r2 - Left Point
	; r3 - Right pointer
	; r4 - Left X
	; r5 - Left DX
	; r6 - Right X
	; r7 - Right DX
	; r8 - Left width
	; r9 - Right width
	; r10 - TOP Y
	; r11 - BOTTOM Y
	; r12 - First base DST
	; r13 - Last base DST
		mov	r1,r2
		mov	r1,r3
		bsr	set_left
		nop
		bsr	set_right
		nop
.next_pz:
		mov	#SCREEN_HEIGHT,r0
		cmp/gt	r0,r10
		bt	.exit
		cmp/ge	r11,r10
		bt	.exit
		mov	@(marsGbl_VdpList_W,gbr),r0
		mov	r0,r1
		mov	#RAM_Mars_VdpDrwList_e,r0
		cmp/ge	r0,r1
		bt	.exit
		stc	sr,@-r15	; Stop interrupts
		stc	sr,r0
		or	#$F0,r0
		ldc	r0,sr
		bsr	put_piece
		nop
		ldc	@r15+,sr	; Restore interrupts

		cmp/gt	r9,r8
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
		mov	r2,r8
		add	#$20,r8
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
		shll16	r0
		mov	r0,r5
		shll16	r4
		sts	mach,r8
		mov	#_JR,r0			; HW DIV
		mov	r8,@r0
		mov	r5,@(4,r0)
		nop
		mov	@(4,r0),r5
		mov	#CachDDA_Src_L+4,r0
		mov	r5,@r0
		mov	#_JR,r0
		mov	r8,@r0
		mov	r4,@(4,r0)
		nop
		mov	@(4,r0),r4
		mov	#CachDDA_Src_L+$C,r0
		mov	r4,@r0
; 		shll2	r8
; 		mov	#RAM_Mars_DivTable,r0		; OLD
; 		mov	@(r0,r8),r0
; 		dmuls	r5,r0
; 		sts	macl,r5
; 		sts	mach,r0
; 		xtrct   r0,r5
; 		mov	#CachDDA_Src_L+4,r0
; 		mov	r5,@r0
; 		mov	#RAM_Mars_DivTable,r0
; 		mov	@(r0,r8),r0
; 		dmuls	r4,r0
; 		sts	macl,r4
; 		sts	mach,r0
; 		xtrct   r0,r4
; 		mov	#CachDDA_Src_L+$C,r0
; 		mov	r4,@r0
		mov	@r2,r5
		sub 	r1,r5
		shll16	r5
		mov 	r1,r4
		shll16	r4
		mov	#_JR,r0				; HW DIV
		mov	r8,@r0
		mov	r5,@(4,r0)
		nop
		mov	@(4,r0),r5
; 		mov	#RAM_Mars_DivTable,r0		; OLD
; 		mov	@(r0,r8),r0
; 		dmuls	r5,r0
; 		sts	macl,r5
; 		sts	mach,r0
; 		xtrct   r0,r5
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
		shll16	r0
		mov	r0,r7
		shll16	r6
		sts	mach,r9
		mov	#_JR,r0				; HW DIV
		mov	r9,@r0
		mov	r7,@(4,r0)
		nop
		mov	@(4,r0),r7
		mov	#CachDDA_Src_R+4,r0
		mov	r7,@r0
		mov	#_JR,r0
		mov	r9,@r0
		mov	r6,@(4,r0)
		nop
		mov	@(4,r0),r6
		mov	#CachDDA_Src_R+$C,r0
		mov	r6,@r0
; 		shll2	r9
; 		mov	#RAM_Mars_DivTable,r0		; OLD
; 		mov	@(r0,r9),r0
; 		dmuls	r7,r0
; 		sts	macl,r7
; 		sts	mach,r0
; 		xtrct   r0,r7
; 		mov	#CachDDA_Src_R+4,r0
; 		mov	r7,@r0
; 		mov	#RAM_Mars_DivTable,r0
; 		mov	@(r0,r9),r0
; 		dmuls	r6,r0
; 		sts	macl,r6
; 		sts	mach,r0
; 		xtrct   r0,r6
; 		mov	#CachDDA_Src_R+$C,r0
; 		mov	r6,@r0
		mov	@r3,r7
		sub 	r1,r7
		shll16	r7
		mov 	r1,r6
		shll16	r6
		mov	#_JR,r0				; HW DIV
		mov	r9,@r0
		mov	r7,@(4,r0)
		nop
		mov	@(4,r0),r7
; 		mov	#RAM_Mars_DivTable,r0		; OLD
; 		mov	@(r0,r9),r0
; 		dmuls	r7,r0
; 		sts	macl,r7
; 		sts	mach,r0
; 		xtrct   r0,r7
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
		dmulu	r0,r5
		sts	macl,r2
		dmulu	r0,r7
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
		dmulu	r0,r7
		sts	macl,r2
		dmulu	r0,r9
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
		dmulu	r0,r7
		sts	macl,r2
		dmulu	r0,r9
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
		mov	r0,@(marsGbl_VdpList_W,gbr)
		mov.w	@(marsGbl_VdpListCnt,gbr),r0
		add	#1,r0
		mov.w	r0,@(marsGbl_VdpListCnt,gbr)
		
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
CachDDA_Top	ds.l 2*2		; First 2 points
CachDDA_Last	ds.l 2*2		; Triangle or Quad (+8)
CachDDA_Src	ds.l 4*2
CachDDA_Src_L	ds.l 4			; X/DX/Y/DX result for textures
CachDDA_Src_R	ds.l 4
CachMdl_Copy	ds.b sizeof_mdlobj
Cach_LnDrw_L	ds.l 10
Cach_LnDrw_S	ds.l 0
Cach_ClrLines	ds.w 1

; ------------------------------------------------
; CACHE END
; ------------------------------------------------

.end:		phase CACHE_START+.end&$1FFF
CACHE_END:
