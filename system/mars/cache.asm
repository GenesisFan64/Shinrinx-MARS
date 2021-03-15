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
		mov	@(plypz_type,r14),r0		; Check material options
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
		mov	#$FF,r0
		mov	@(plypz_mtrl,r14),r11		; r11 - texture data
		mov	@(plypz_type,r14),r4		;  r4 - texture width|palinc
		mov	r4,r13
		shlr16	r4
		and	r2,r4
		and	r0,r13
		mov	r9,@-r15
.tex_xloop:
		mov	r7,r2
		shlr16	r2
		mulu	r2,r4
		mov	r5,r2	   			; Build column index
		sts	macl,r0
		shlr16	r2
		add	r2,r0
		mov.b	@(r0,r11),r0			; Read pixel
; 		cmp/eq	#0,r0				; If texture pixel == 0
; 		bt	.blnk				; then don't add
		add	r13,r0
		and	#$FF,r0
; .blnk:
		mov.b	r0,@r10	   			; Write pixel
		add 	#1,r10
		add	r6,r5				; Update X
		dt	r12
		bf/s	.tex_xloop
		add	r8,r7				; Update Y
		mov	@r15+,r9
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
		mov	@(plypz_type,r14),r5
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
		mov 	r0,@(plypz_type,r1)
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