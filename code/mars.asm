; ====================================================================		
; ----------------------------------------------------------------
; MARS SH2 Section, CODE for both CPUs, RAM usage and
; DATA goes here
; ----------------------------------------------------------------

		phase CS3			; now we are at SDRAM
		cpu SH7600			; should be SH7095 but ASL doesn't have it, this is close enough

; =================================================================

		include "system/mars/head.asm"

; ====================================================================
; ----------------------------------------------------------------
; MARS Global variables (for gbr)
; ----------------------------------------------------------------

			struct 0
marsGbl_VdpList_R	ds.l 1
marsGbl_VdpList_W	ds.l 1
marsGbl_CurrFacePos	ds.l 1
marsGbl_CurrZList	ds.l 1
marsGbl_PolyBuffNum	ds.w 1
marsGbl_MdlFacesCntr	ds.w 1
marsGbl_VdpListCnt	ds.w 1
marsGbl_DrwTask		ds.w 1
marsGbl_VIntFlag_M	ds.w 1
marsGbl_VIntFlag_S	ds.w 1
sizeof_MarsGbl		ds.l 0
			finish
			
; ====================================================================
; ----------------------------------------------------------------
; Error trap
; ----------------------------------------------------------------

SH2_Error:
		nop
		bra	SH2_Error
		nop
		align 4

; ====================================================================		
; ----------------------------------------------------------------
; MARS Interrupts for both CPUs
; ----------------------------------------------------------------

; =================================================================
; ------------------------------------------------
; Master | Unused interrupt
; ------------------------------------------------

m_irq_bad:
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Master | PWM Interrupt
; ------------------------------------------------

m_irq_pwm:
		mov	#_sysreg+monowidth,r1
		mov.b	@r1,r0
 		tst	#$80,r0
 		bf	.exit
		mov.l	r2,@-r15
		mov.l	r3,@-r15
		mov.l	r4,@-r15
		mov.l	r5,@-r15
		mov.l	r6,@-r15
		mov.l	r7,@-r15
		mov.l	r8,@-r15
		sts	pr,@-r15
		bsr	MarsSound_PWM
		nop
		lds	@r15+,pr
		mov.l	@r15+,r8
		mov.l	@r15+,r7
		mov.l	@r15+,r6
		mov.l	@r15+,r5
		mov.l	@r15+,r4
		mov.l	@r15+,r3
		mov.l	@r15+,r2
.exit:
		mov.l	#$FFFFFE10,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+pwmintclr,r1
		mov.w	r0,@r1
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Master | CMD Interrupt
; ------------------------------------------------

m_irq_cmd:
		mov.l	#$FFFFFE10,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+cmdintclr,r1
		mov.w	r0,@r1
		nop
		nop
		nop
		nop
		nop
		rts
		nop
		align 4
		
; =================================================================
; ------------------------------------------------
; Master | HBlank
; ------------------------------------------------

m_irq_h:
		mov.l	#$FFFFFE10,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+hintclr,r1
		mov.w	r0,@r1
		nop
		nop
		nop
		nop
		nop
		rts
		nop
		align 4
		
; =================================================================
; ------------------------------------------------
; Master | VBlank
; ------------------------------------------------

m_irq_v:
; ----------------------------------
; Palette can be updated only in
; VBlank
; ----------------------------------
		mov 	#_vdpreg,r1
.min_r		mov.w	@(10,r1),r0		; Wait for FEN to clear
		and	#%10,r0
		cmp/eq	#2,r0
		bt	.min_r
		mov.l	r2,@-r15		; Send palette from ROM to Super VDP
		mov.l	r3,@-r15
		mov.l	r4,@-r15
		mov.l	r5,@-r15
		mov.l	r6,@-r15
		mov.l	#_vdpreg,r1		; Wait for palette access ok
.wait		mov.b	@(vdpsts,r1),r0
		tst	#$20,r0
		bt	.wait
		mov.l	#RAM_Mars_Palette,r1	; Send palette from cache
		mov.l	#_palette,r2
 		mov.l	#256,r3
		mov.l	#%0101011011110001,r4	; transfer size 2 / burst
		mov.l	#_DMASOURCE0,r5 	; _DMASOURCE = $ffffff80
		mov.l	#_DMAOPERATION,r6 	; _DMAOPERATION = $ffffffb0
		mov.l	r1,@r5			; set source address
		mov.l	r2,@(4,r5)		; set destination address
		mov.l	r3,@(8,r5)		; set length
		xor	r0,r0
		mov.l	r0,@r6			; Stop OPERATION
		xor	r0,r0
		mov.l	r0,@($C,r5)		; clear TE bit
		mov.l	r4,@($C,r5)		; load mode
		add	#1,r0
		mov.l	r0,@r6			; Start OPERATION

		mov.l	@r15+,r6
		mov.l	@r15+,r5
		mov.l	@r15+,r4
		mov.l	@r15+,r3
		mov.l	@r15+,r2

		mov 	#0,r0
		mov.w	r0,@(marsGbl_VIntFlag_M,gbr)
		mov.l	#$FFFFFE10,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+vintclr,r1
		rts
		mov.w	r0,@r1
		align 4
		
; =================================================================
; ------------------------------------------------
; Master | VRES Interrupt
; ------------------------------------------------

m_irq_vres:
		mov.l	#_sysreg,r0
		ldc	r0,gbr
		mov.w	r0,@(vresintclr,gbr)	; V interrupt clear
		mov.b	@(dreqctl,gbr),r0
		tst	#1,r0
		bf	.mars_reset
.md_reset:
		mov.l	#"68UP",r1		; wait for the 68k to show up
		mov.l	@(comm12,gbr),r0
		cmp/eq	r0,r1
		bf	.md_reset
.sh_wait:
		mov.l	#"S_OK",r1		; wait for the slave to show up
		mov.l	@(comm4,gbr),r0
		cmp/eq	r0,r1
		bf	.sh_wait

		mov.l	#"M_OK",r0		; let the others know master ready
		mov.l	r0,@(comm0,gbr)
		mov.l	#CS3|$40000-8,r15
		mov.l	#SH2_M_HotStart,r0
		mov.l	r0,@r15
		mov.w	#$F0,r0
		mov.l	r0,@(4,r15)
		mov.l	#_DMAOPERATION,r1
		mov.l	#0,r0
		mov.l	r0,@r1			; DMA off
		mov.l	#_DMACHANNEL0,r1
		mov.l	#0,r0
		mov.l	r0,@r1
		mov.l	#%0100010011100000,r1
		mov.l	r0,@r1			; Channel control
		rte
		nop
.mars_reset:
		mov.l	#_FRT,r1
		mov.b	@(_TOCR,r1),r0
		or	#$01,r0
		mov.b	r0,@(_TOCR,r1)
.vresloop:
		bra	.vresloop
		nop
		align 4

		ltorg		; Save MASTER IRQ literals here

; =================================================================
; ------------------------------------------------
; Unused
; ------------------------------------------------

s_irq_bad:
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Slave | PWM Interrupt
; ------------------------------------------------

s_irq_pwm:
		mov.l	#$FFFFFE10,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+pwmintclr,r1
		mov.w	r0,@r1
		nop
		nop
		nop
		nop
		nop
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Slave | CMD Interrupt
; ------------------------------------------------

s_irq_cmd:
		mov.l	#$FFFFFE10,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+cmdintclr,r1
		mov.w	r0,@r1
		nop
		nop
		nop
		nop
		nop
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Slave | HBlank
; ------------------------------------------------

s_irq_h:
		mov.l	#$FFFFFE10,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+hintclr,r1
		mov.w	r0,@r1
		nop
		nop
		nop
		nop
		nop
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Slave | VBlank
; ------------------------------------------------

s_irq_v:
		mov 	#0,r0
		mov.w	r0,@(marsGbl_VIntFlag_S,gbr)
		
		mov.l	#$FFFFFE10,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+vintclr,r1
		rts
		mov.w	r0,@r1
		align 4

; =================================================================
; ------------------------------------------------
; Slave | VRES Interrupt
; ------------------------------------------------

s_irq_vres:
		mov.l	#_sysreg,r0
		ldc	r0,gbr
		mov.w	r0,@(vresintclr,gbr)	; V interrupt clear
		mov.b	@(dreqctl,gbr),r0
		tst	#1,r0
		bf	.mars_reset
.md_reset:
		mov.l	#"68UP",r1		; wait for the 68k to show up
		mov.l	@(comm12,gbr),r0
		cmp/eq	r0,r1
		bf	.md_reset
		mov.l	#"S_OK",r0		; tell the others slave is ready
		mov.l	r0,@(comm4,gbr)
.sh_wait:
		mov.l	#"M_OK",r1		; wait for the slave to show up
		mov.l	@(comm0,gbr),r0
		cmp/eq	r0,r1
		bf	.sh_wait

		mov.l	#CS3|$3F000-8,r15
		mov.l	#SH2_S_HotStart,r0
		mov.l	r0,@r15
		mov.w	#$F0,r0
		mov.l	r0,@(4,r15)
		mov.l	#_DMAOPERATION,r1
		mov.l	#0,r0
		mov.l	r0,@r1			; DMA off
		mov.l	#_DMACHANNEL0,r1
		mov.l	#0,r0
		mov.l	r0,@r1
		mov.l	#%0100010011100000,r1
		mov.l	r0,@r1			; Channel control
		rte
		nop
.mars_reset:
		mov.l	#_FRT,r1
		mov.b	@(_TOCR,r1),r0
		or	#$01,r0
		mov.b	r0,@(_TOCR,r1)
.vresloop:
		bra	.vresloop
		nop
		align 4

		ltorg			; Save Slave IRQ literals

; =================================================================
; ------------------------------------------------
; Slave | Custom interrupt
; ------------------------------------------------

s_irq_custom:
		mov	r2,@-r15
		mov.l   #_FRT,r1
		mov.b   @(7,r1),r0
		xor     #2,r0
		mov.b   r0,@(7,r1)
		
		mov	#CS3+$44,r1
		mov	@r1,r0
		add 	#1,r0
		mov	r0,@r1

		mov	#1,r2
		mov	#$FFFFFE80,r1
		mov.w   #$A518,r0
		mov.w   r0,@r1
		or      #$20,r0
		mov.w   r0,@r1
		mov.w   #$5A00,r0
		or	r2,r0
		mov.w	r0,@r1
		mov	@r15+,r2
		rts
		nop
		align 4

; ====================================================================
; ----------------------------------------------------------------
; MARS System features
; ----------------------------------------------------------------

		include "system/mars/video.asm"
		include "system/mars/sound.asm"
		align 4

; ====================================================================
; ----------------------------------------------------------------
; Master entry
; ----------------------------------------------------------------

		align 4
SH2_M_Entry:
		mov.l	#CS3|$40000,r15
		mov.l   #$FFFFFE10,r1
		mov     #0,r0
		mov.b   r0,@(0,r1)
		mov     #$FFFFFFE2,r0
		mov.b   r0,@(7,r1)
		mov     #0,r0
		mov.b   r0,@(4,r1)
		mov     #1,r0
		mov.b   r0,@(5,r1)
		mov     #0,r0
		mov.b   r0,@(6,r1)
		mov     #1,r0
		mov.b   r0,@(1,r1)
		mov     #0,r0
		mov.b   r0,@(3,r1)
		mov.b   r0,@(2,r1)
		mov.l   #$FFFFFEE2,r0
		mov     #$50,r1
		mov.w   r1,@r0
		mov.l   #$FFFFFEE4,r0
		mov     #$120/4,r1		; VBR + this/4
		shll8   r1
		mov.w   r1,@r0

; ------------------------------------------------
; Wait for Genesis and Slave CPU
; ------------------------------------------------

.wait_md:
		mov 	#_sysreg+comm0,r2
		mov.l	@r2,r0
		cmp/eq	#0,r0
		bf	.wait_md
		mov.l	#"SLAV",r1
.wait_slave:
		mov.l	@(8,r2),r0			; wait for the slave to finish booting
		cmp/eq	r1,r0
		bf	.wait_slave
		mov.l	#0,r0				; clear SLAV
		mov.l	r0,@(8,r2)

; ********************************************************
; Your MASTER CPU code starts here
; ********************************************************

SH2_M_HotStart:
		mov.l	#CS3|$40000,r15
		mov.l	#RAM_Mars_Global,r14
		ldc	r14,gbr
	
		mov.l	#$F0,r0				; Interrupts OFF
		ldc	r0,sr
		mov.l	#_CCR,r1			; Set this cache mode
		mov	#0,r0
		mov.w	r0,@r1
		mov	#$19,r0
		mov.w	r0,@r1
		mov	#_sysreg,r1
		mov.l	#VIRQ_ON|PWMIRQ_ON|CMDIRQ_ON,r0	; IRQ enable bits
    		mov.b	r0,@(intmask,r1)

; ------------------------------------------------

		bsr	MarsVideo_Init			; Init video
		nop
		bsr	MarsSound_Init			; Init sound
		nop
		mov	#Palette_Puyo,r1
		mov	#256,r3
		bsr	MarsVideo_LoadPal
		mov	#0,r2
		mov	#$1F<<10,r0
		mov	#RAM_Mars_Palette,r1
		mov.w	r0,@r1
		
		mov 	#CACHE_START,r1			; VIDEO Routines	
		mov 	#$C0000000,r2
		mov 	#(CACHE_END-CACHE_START)/4,r3
.copy:
		mov 	@r1+,r0
		mov 	r0,@r2
		add 	#4,r2
		dt	r3
		bf	.copy

; 		mov	#0,r1
; 		mov	#WAV_LEFT,r2
; 		mov	#WAV_LEFT_E,r3
; 		mov	r2,r4
; 		mov	#$100,r5
; 		mov	#0,r6
; 		bsr	MarsSound_SetChannel
; 		mov	#%10,r7
; 		mov	#1,r1
; 		mov	#WAV_RIGHT,r2
; 		mov	#WAV_RIGHT_E,r3
; 		mov	r2,r4
; 		mov	#$100,r5
; 		mov	#0,r6
; 		bsr	MarsSound_SetChannel
; 		mov	#%01,r7
		
; ------------------------------------------------

		mov	#$FFFFFE92,r0
		mov     #8,r1
		mov.b   r1,@r0
		mov     #$19,r1
		mov.b   r1,@r0
		mov.l	#$20,r0			; Interrupts ON
		ldc	r0,sr

; --------------------------------------------------------
; Loop
; --------------------------------------------------------

master_loop:
		mov	#0,r0
		mov	#_sysreg+comm14,r1
		mov.b	r0,@r1
.mstr_wait:
		mov.b	@r1,r0
		cmp/eq	#0,r0
		bf	.mstr_free
; 		mov.l	#$64,r0
		mov	#$16,r0
.mstr_delay:
		nop
		dt	r0
		bf/s	.mstr_delay
		nop
		bra	.mstr_wait
		nop
; --------------------------------------------------------

.mstr_free:
		mov.l	#$FFFFFE92,r0
		mov	#8,r1
		mov.b	r1,@r0
		mov	#$19,r1
		mov.b	r1,@r0
		bsr	MarsRndr_SetWatchdog
		nop
		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
		tst     #1,r0
		bt	.page_2
		mov 	#RAM_Mars_PlgnList_0,r14
		mov	#RAM_Mars_PlgnNum_0,r13
		bra	.cont_plgn
		nop
.page_2:
		mov 	#RAM_Mars_PlgnList_1,r14
		mov	#RAM_Mars_PlgnNum_1,r13
.cont_plgn:
		mov.w	@r13,r13
		cmp/pl	r13
		bf	.skip
.loop:
		mov	r14,@-r15
		mov	r13,@-r15
		mov	@r14,r14
		cmp/pl	r14
		bf	.bad_one
		mov 	#MarsVideo_MakePolygon,r0
		jsr	@r0
		nop
.bad_one:
		mov	@r15+,r13
		mov	@r15+,r14
		add	#4,r14
		dt	r13
		bf	.loop
.skip:

	; --------------------------------------

.wait_pz:	mov.w	@(marsGbl_VdpListCnt,gbr),r0
		cmp/eq	#0,r0
		bf	.wait_pz
.wait_task:	mov.w	@(marsGbl_DrwTask,gbr),r0
		cmp/eq	#0,r0
		bf	.wait_task
		mov.l   #$FFFFFE80,r2			; Watchdog stop
		mov.w   #$A518,r0
		mov.w   r0,@r2
		bsr	MarsVideo_FrameSwap		; Swap frame (waits VBlank)
		nop
		mov	#_sysreg+comm4,r1
		mov.w	@r1,r0
		add	#1,r0
		mov.w	r0,@r1

		bra	master_loop
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Slave entry
; ----------------------------------------------------------------

		align 4
SH2_S_Entry:
		mov.l	#_sysreg,r14
		ldc	r14,gbr

		mov.l   #$FFFFFE10,r1
		mov     #0,r0
		mov.b   r0,@(0,r1)
		mov     #$FFFFFFE2,r0
		mov.b   r0,@(7,r1)
		mov     #0,r0
		mov.b   r0,@(4,r1)
		mov     #1,r0
		mov.b   r0,@(5,r1)
		mov     #0,r0
		mov.b   r0,@(6,r1)
		mov     #1,r0
		mov.b   r0,@(1,r1)
		mov     #0,r0
		mov.b   r0,@(3,r1)
		mov.b   r0,@(2,r1)
		mov.l   #$FFFFFEE2,r0
		mov     #$50,r1
		mov.w   r1,@r0
		mov.l   #$FFFFFEE4,r0
		mov     #$120/4,r1		; VBR + this/4
		shll8   r1
		mov.w   r1,@r0
		
; ------------------------------------------------
; Wait for Genesis, report to Master SH2
; ------------------------------------------------

.wait_md:
		mov 	#_sysreg+comm0,r2
		mov.l	@r2,r0
		cmp/eq	#0,r0
		bf	.wait_md
		mov.l	#"SLAV",r0
		mov.l	r0,@(8,r2)

; ********************************************************
; Your SLAVE code starts here
; ********************************************************

SH2_S_HotStart:
		mov.l	#CS3|$3F000,r15		; Reset stack
		mov.l	#RAM_Mars_Global,r14	; Reset gbr
		ldc	r14,gbr
		mov.l	#$F0,r0			; Interrupts OFF
		ldc	r0,sr
		mov.l	#_CCR,r1		; Set this cache mode
		mov	#0,r0
		mov.w	r0,@r1
		mov	#$19,r0
		mov.w	r0,@r1
		mov	#_sysreg,r1
		mov.l	#VIRQ_ON|CMDIRQ_ON,r0	; IRQ enable bits
    		mov.b	r0,@(intmask,r1)	; clear IRQ ACK regs

	; Generate division tables
		bsr	MarsMdl_Init
		nop
		
; ------------------------------------------------

		mov	#$20,r0			; Interrupts ON
		ldc	r0,sr
		mov	#RAM_Mars_Objects,r1
		mov	#TEST_MODEL,r0
		mov	r0,@r1
; 		mov	#-$C000,r0
; 		mov	r0,@(mdl_z_pos,r1)

; --------------------------------------------------------
; Loop
; --------------------------------------------------------

slave_loop:
		mov	#_sysreg+comm15,r14
		mov.b	@r14,r0
		cmp/eq	#0,r0
		bt	.no_requests
		mov	#_sysreg+comm8,r1
		mov	#RAM_Mars_ObjCamera,r2
.transfer_loop:
		nop
		nop
		nop
		nop
		mov.w	@r1,r0
		cmp/eq	#0,r0
		bt	.transfer_loop
		cmp/eq	#2,r0
		bt	.trnsfr_done
		mov.w	@(2,r1),r0
		extu	r0,r0
		shll16	r0
		mov	r0,r3
		mov.w	@(4,r1),r0
		extu	r0,r0
		or	r3,r0
		mov.l	r0,@r2
		nop
		nop
		nop
		nop
		mov	#0,r0
		mov.w	r0,@r1
		nop
		nop
		nop
		nop
		bra	.transfer_loop
		add	#4,r2
.trnsfr_done:
		mov	#0,r0
		mov.w	r0,@r1
		mov.b	r0,@r14
.no_requests:

; --------------------------------------------
; Main slave CPU job
; --------------------------------------------

; 		mov	#RAM_Mars_Objects,r2
; 		mov	#$400,r1
; 		mov	@(mdl_x_rot,r2),r0
; 		add	r1,r0
; 		mov	r0,@(mdl_x_rot,r2)
; 		mov	@(mdl_y_rot,r2),r0
; 		add	r1,r0
; 		mov	r0,@(mdl_y_rot,r2)


; ----------------------------------------

		mov	#_sysreg+comm6,r1		; DEBUG counter
		mov.w	@r1,r0
		add	#1,r0
		mov.w	r0,@r1
		mov	#0,r0
		mov.w	r0,@(marsGbl_MdlFacesCntr,gbr)
		mov 	#RAM_Mars_Polygons_0,r1
		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
		tst     #1,r0
		bt	.go_mdl
		mov 	#RAM_Mars_Polygons_1,r1
.go_mdl:
		mov	r1,r0
		mov	r0,@(marsGbl_CurrFacePos,gbr)
		mov	#RAM_Mars_Plgn_ZList,r0
		mov	r0,@(marsGbl_CurrZList,gbr)
		mov	#RAM_Mars_Objects,r14
		mov	#0,r13
		mov	#MAX_MODELS,r12
.loop:
		mov	@(mdl_data,r14),r0
		cmp/eq	#0,r0
		bt	.invlid
		mov	r12,@-r15
		bsr	MarsMdl_MakeModel
		nop
		mov	@r15+,r12
.invlid:
		dt	r12
		bf/s	.loop
		add	#sizeof_mdlobj,r14
.skip:

; ----------------------------------------

		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
		tst     #1,r0
		bf	.page_2
		mov 	#RAM_Mars_PlgnList_0,r14
		mov 	#RAM_Mars_PlgnNum_0,r13
		bsr	slv_check_z
		nop
		bra	.swap_now
		nop
.page_2:
		mov 	#RAM_Mars_PlgnList_1,r14
		mov 	#RAM_Mars_PlgnNum_1,r13
		bsr	slv_check_z
		nop

.swap_now:
		mov.w	@r13,r0
		mov	#_sysreg+comm0,r1
		mov.w	r0,@r1

		bsr	Slv_WaitMaster
		nop
		mov.w	@(marsGbl_PolyBuffNum,gbr),r0
 		xor	#1,r0
 		mov.w	r0,@(marsGbl_PolyBuffNum,gbr)

		bsr	Slv_SetMasterTask
		mov	#1,r2
		bra	slave_loop
		nop
		align 4
		ltorg

; ----------------------------------------
; Bubble sorting
	
slv_check_z:
		sts	pr,@-r15
		mov	#0,r0
		mov.w	r0,@r13

		mov	#RAM_Mars_Plgn_ZList,r12
		mov.w	@(marsGbl_MdlFacesCntr,gbr),r0
		cmp/eq	#0,r0
		bt	.z_end
		mov	#2,r11
		cmp/gt	r11,r0
		bt	.z_normal
		mov	r0,r11
		bra	.set_now
		nop
.z_normal:
		mov	#MAX_FACES,r11
		cmp/ge	r11,r0
		bf	.z_ranout
		mov	r11,r0
.z_ranout:
		mov	r0,r11
		mov	r0,r10
		add	#-1,r10
		mov	r10,r7
		add	#-1,r7
		cmp/pl	r7
		bf	.z_end
.z_outer:
		mov	r10,r8
		mov	r12,r9
.z_inner:
		mov	@r9,r0
		mov	@(8,r9),r1
		cmp/gt	r1,r0
		bf	.z_high
		mov	r1,@r9
		mov	r0,@(8,r9)
		mov	@(4,r9),r0
		mov	@($C,r9),r1
		mov	r1,@(4,r9)
		mov	r0,@($C,r9)
.z_high:
		dt	r8
		bf/s	.z_inner
		add	#8,r9
		dt	r7
		bf	.z_outer

; ----------------------------------------

.set_now:
		mov	r12,r10
		mov	r11,r9
		mov	#0,r8
.next_face:
		mov	@(4,r10),r7
		cmp/pl	r7
		bf	.no_face
		mov	#0,r0
		mov	r0,@(4,r10)
		mov	r7,@r14
		add	#4,r14
		add	#1,r8
.no_face:
		dt	r9
		bf/s	.next_face
		add 	#8,r10
		mov.w	r8,@r13
.z_end:
		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; ----------------------------------------

Slv_SetMasterTask:
		mov.l	#_sysreg+comm14,r1
		mov.b	r2,@r1
		rts
		nop
		align 4

Slv_WaitMaster:
		mov.l	#_sysreg+comm14,r1
.wait_master:
		mov.b	@r1,r0
		cmp/eq	#0,r0
		bt	.master_free
; 		mov	#$44C,r0
		mov	#$11C,r0
.wait_delay:
		dt	r0
		bf	.wait_delay
		bra	.wait_master
		nop
.master_free:
		rts
		nop
		align 4

; ----------------------------------------

		ltorg

; ====================================================================
; ----------------------------------------------------------------
; MARS DATA
; ----------------------------------------------------------------

		align 4
sin_table	binclude "system/mars/data/sinedata.bin"
		align 4

persp_table_max:
 dc.l 3584
 dc.l 3942
 dc.l 4300
 dc.l 4659
 dc.l 5017
 dc.l 5376
 dc.l 5734
 dc.l 6092
 dc.l 6451
 dc.l 6809
 dc.l 7168
 dc.l 7526
 dc.l 7884
 dc.l 8243
 dc.l 8601
 dc.l 8960
 dc.l 9318
 dc.l 9676
 dc.l 10035
 dc.l 10393
 dc.l 10752
 dc.l 11110
 dc.l 11468
 dc.l 11827
 dc.l 12185
 dc.l 12544
 dc.l 12902
 dc.l 13260
 dc.l 13619
 dc.l 13977
 dc.l 14336
 dc.l 14694
 dc.l 15052
 dc.l 15411
 dc.l 15769
 dc.l 16128
 dc.l 16486
 dc.l 16844
 dc.l 17203
 dc.l 17561
 dc.l 17919
 dc.l 18278
 dc.l 18636
 dc.l 18995
 dc.l 19353
 dc.l 19711
 dc.l 20070
 dc.l 20428
 dc.l 20787
 dc.l 21145
 dc.l 21503
 dc.l 21862
 dc.l 22220
 dc.l 22579
 dc.l 22937
 dc.l 23295
 dc.l 23654
 dc.l 24012
 dc.l 24371
 dc.l 24729
 dc.l 25087
 dc.l 25446
 dc.l 25804
 dc.l 26163
 dc.l 26521
 dc.l 26879
 dc.l 27238
 dc.l 27596
 dc.l 27955
 dc.l 28313
 dc.l 28671
 dc.l 29030
 dc.l 29388
 dc.l 29747
 dc.l 30105
 dc.l 30463
 dc.l 30822
 dc.l 31180
 dc.l 31539
 dc.l 31897
 dc.l 32255
 dc.l 32614
 dc.l 32972
 dc.l 33331
 dc.l 33689
 dc.l 34047
 dc.l 34406
 dc.l 34764
 dc.l 35123
 dc.l 35481
 dc.l 35839
 dc.l 36198
 dc.l 36556
 dc.l 36915
 dc.l 37273
 dc.l 37631
 dc.l 37990
 dc.l 38348
 dc.l 38707
 dc.l 39065
 dc.l 39423
 dc.l 39782
 dc.l 40140
 dc.l 40499
 dc.l 40857
 dc.l 41215
 dc.l 41574
 dc.l 41932
 dc.l 42291
 dc.l 42649
 dc.l 43007
 dc.l 43366
 dc.l 43724
 dc.l 44083
 dc.l 44441
 dc.l 44799
 dc.l 45158
 dc.l 45516
 dc.l 45875
 dc.l 46233
 dc.l 46591
 dc.l 46950
 dc.l 47308
 dc.l 47667
 dc.l 48025
 dc.l 48383
 dc.l 48742
 dc.l 49100
 dc.l 49459
 dc.l 49817
 dc.l 50175
 dc.l 50534
 dc.l 50892
 dc.l 51251
 dc.l 51609
 dc.l 51967
 dc.l 52326
 dc.l 52684
 dc.l 53043
 dc.l 53401
 dc.l 53759
 dc.l 54118
 dc.l 54476
 dc.l 54835
 dc.l 55193
 dc.l 55551
 dc.l 55910
 dc.l 56268
 dc.l 56627
 dc.l 56985
 dc.l 57343
 dc.l 57702
 dc.l 58060
 dc.l 58419
 dc.l 58777
 dc.l 59135
 dc.l 59494
 dc.l 59852
 dc.l 60211
 dc.l 60569
 dc.l 60927
 dc.l 61286
 dc.l 61644
 dc.l 62003
 dc.l 62361
 dc.l 62719
 dc.l 63078
 dc.l 63436
 dc.l 63795
 dc.l 64153
 dc.l 64511
 dc.l 64870
 dc.l 65228
 dc.l 65587
 dc.l 65945
 dc.l 66303
 dc.l 66662
 dc.l 67020
 dc.l 67379
 dc.l 67737
 dc.l 68096
 dc.l 68454
 dc.l 68812
 dc.l 69171
 dc.l 69529
 dc.l 69888
 dc.l 70246
 dc.l 70604
 dc.l 70963
 dc.l 71321
 dc.l 71680
 dc.l 72038
 dc.l 72396
 dc.l 72755
 dc.l 73113
 dc.l 73472
 dc.l 73830
 dc.l 74188
 dc.l 74547
 dc.l 74905
 dc.l 75264
 dc.l 75622
 dc.l 75980
 dc.l 76339
 dc.l 76697
 dc.l 77056
 dc.l 77414
 dc.l 77772
 dc.l 78131
 dc.l 78489
 dc.l 78848
 dc.l 79206
 dc.l 79564
 dc.l 79923
 dc.l 80281
 dc.l 80640
 dc.l 80998
 dc.l 81356
 dc.l 81715
 dc.l 82073
 dc.l 82432
 dc.l 82790
 dc.l 83148
 dc.l 83507
 dc.l 83865
 dc.l 84224
 dc.l 84582
 dc.l 84940
 dc.l 85299
 dc.l 85657
 dc.l 86016
 dc.l 86374
 dc.l 86732
 dc.l 87091
 dc.l 87449
 dc.l 87808
 dc.l 88166
 dc.l 88524
 dc.l 88883
 dc.l 89241
 dc.l 89600
 dc.l 89958
 dc.l 90316
 dc.l 90675
 dc.l 91033
 dc.l 91392
 dc.l 91750
 dc.l 92108
 dc.l 92467
 dc.l 92825
 dc.l 93184
 dc.l 93542
 dc.l 93900
 dc.l 94259
 dc.l 94617
 dc.l 94976
 dc.l 95334
 dc.l 95692
 dc.l 96051
 dc.l 96409
 dc.l 96768
 dc.l 97126
 dc.l 97484
 dc.l 97843
 dc.l 98201
 dc.l 98560
 dc.l 98918
 dc.l 99276
 dc.l 99635
 dc.l 99993
 dc.l 100352
 dc.l 100710
 dc.l 101068
 dc.l 101427
 dc.l 101785
 dc.l 102144
 dc.l 102502
 dc.l 102860
 dc.l 103219
 dc.l 103577
 dc.l 103936
 dc.l 104294
 dc.l 104652
 dc.l 105011
 dc.l 105369
 dc.l 105728
 dc.l 106086
 dc.l 106444
 dc.l 106803
 dc.l 107161
 dc.l 107520
 dc.l 107878
 dc.l 108236
 dc.l 108595
 dc.l 108953
 dc.l 109312
 dc.l 109670
 dc.l 110028
 dc.l 110387
 dc.l 110745
 dc.l 111104
 dc.l 111462
 dc.l 111820
 dc.l 112179
 dc.l 112537
 dc.l 112896
 dc.l 113254
 dc.l 113612
 dc.l 113971
 dc.l 114329
 dc.l 114688
 dc.l 115046
 dc.l 115404
 dc.l 115763
 dc.l 116121
 dc.l 116480
 dc.l 116838
 dc.l 117196
 dc.l 117555
 dc.l 117913
 dc.l 118272
 dc.l 118630
 dc.l 118988
 dc.l 119347
 dc.l 119705
 dc.l 120064
 dc.l 120422
 dc.l 120780
 dc.l 121139
 dc.l 121497
 dc.l 121856
 dc.l 122214
 dc.l 122572
 dc.l 122931
 dc.l 123289
 dc.l 123648
 dc.l 124006
 dc.l 124364
 dc.l 124723
 dc.l 125081
 dc.l 125440
 dc.l 125798
 dc.l 126156
 dc.l 126515
 dc.l 126873
 dc.l 127232
 dc.l 127590
 dc.l 127948
 dc.l 128307
 dc.l 128665
 dc.l 129024
 dc.l 129382
 dc.l 129740
 dc.l 130099
 dc.l 130457
 dc.l 130816
 dc.l 131174
 dc.l 131532
 dc.l 131891
 dc.l 132249
 dc.l 132608
 dc.l 132966
 dc.l 133324
 dc.l 133683
 dc.l 134041
 dc.l 134400
 dc.l 134758
 dc.l 135116
 dc.l 135475
 dc.l 135833
 dc.l 136192
 dc.l 136550
 dc.l 136908
 dc.l 137267
 dc.l 137625
 dc.l 137984
 dc.l 138342
 dc.l 138700
 dc.l 139059
 dc.l 139417
 dc.l 139776
 dc.l 140134
 dc.l 140492
 dc.l 140851
 dc.l 141209
 dc.l 141568
 dc.l 141926
 dc.l 142284
 dc.l 142643
 dc.l 143001
 dc.l 143360
 dc.l 143718
 dc.l 144076
 dc.l 144435
 dc.l 144793
 dc.l 145152
 dc.l 145510
 dc.l 145868
 dc.l 146227
 dc.l 146585
 dc.l 146944
 dc.l 147302
 dc.l 147660
 dc.l 148019
 dc.l 148377
 dc.l 148736
 dc.l 149094
 dc.l 149452
 dc.l 149811
 dc.l 150169
 dc.l 150528
 dc.l 150886
 dc.l 151244
 dc.l 151603
 dc.l 151961
 dc.l 152320
 dc.l 152678
 dc.l 153036
 dc.l 153395
 dc.l 153753
 dc.l 154112
 dc.l 154470
 dc.l 154828
 dc.l 155187
 dc.l 155545
 dc.l 155904
 dc.l 156262
 dc.l 156620
 dc.l 156979
 dc.l 157337
 dc.l 157696
 dc.l 158054
 dc.l 158412
 dc.l 158771
 dc.l 159129
 dc.l 159488
 dc.l 159846
 dc.l 160204
 dc.l 160563
 dc.l 160921
 dc.l 161280
 dc.l 161638
 dc.l 161996
 dc.l 162355
 dc.l 162713
 dc.l 163072
 dc.l 163430
 dc.l 163788
 dc.l 164147
 dc.l 164505
 dc.l 164864
 dc.l 165222
 dc.l 165580
 dc.l 165939
 dc.l 166297
 dc.l 166656
 dc.l 167014
 dc.l 167372
 dc.l 167731
 dc.l 168089
 dc.l 168448
 dc.l 168806
 dc.l 169164
 dc.l 169523
 dc.l 169881
 dc.l 170240
 dc.l 170598
 dc.l 170956
 dc.l 171315
 dc.l 171673
 dc.l 172032
 dc.l 172390
 dc.l 172748
 dc.l 173107
 dc.l 173465
 dc.l 173824
 dc.l 174182
 dc.l 174540
 dc.l 174899
 dc.l 175257
 dc.l 175616
 dc.l 175974
 dc.l 176332
 dc.l 176691
 dc.l 177049
 dc.l 177408
 dc.l 177766
 dc.l 178124
 dc.l 178483
 dc.l 178841
 dc.l 179200
 dc.l 179558
 dc.l 179916
 dc.l 180275
 dc.l 180633
 dc.l 180992
 dc.l 181350
 dc.l 181708
 dc.l 182067
 dc.l 182425
 dc.l 182784
 dc.l 183142
 dc.l 183500
 dc.l 183859
 dc.l 184217
 dc.l 184576
 dc.l 184934
 dc.l 185292
 dc.l 185651
 dc.l 186009
 dc.l 186368
 dc.l 186726




persp_table_min:
 dc.l 3584
 dc.l 3318
 dc.l 3089
 dc.l 2890
 dc.l 2715
 dc.l 2560
 dc.l 2421
 dc.l 2297
 dc.l 2185
 dc.l 2083
 dc.l 1991
 dc.l 1906
 dc.l 1828
 dc.l 1756
 dc.l 1690
 dc.l 1629
 dc.l 1571
 dc.l 1518
 dc.l 1468
 dc.l 1422
 dc.l 1378
 dc.l 1337
 dc.l 1298
 dc.l 1262
 dc.l 1227
 dc.l 1194
 dc.l 1163
 dc.l 1134
 dc.l 1106
 dc.l 1079
 dc.l 1054
 dc.l 1029
 dc.l 1006
 dc.l 984
 dc.l 963
 dc.l 943
 dc.l 923
 dc.l 905
 dc.l 887
 dc.l 869
 dc.l 853
 dc.l 837
 dc.l 822
 dc.l 807
 dc.l 792
 dc.l 779
 dc.l 765
 dc.l 752
 dc.l 740
 dc.l 728
 dc.l 716
 dc.l 705
 dc.l 694
 dc.l 684
 dc.l 673
 dc.l 663
 dc.l 654
 dc.l 644
 dc.l 635
 dc.l 626
 dc.l 617
 dc.l 609
 dc.l 601
 dc.l 593
 dc.l 585
 dc.l 578
 dc.l 570
 dc.l 563
 dc.l 556
 dc.l 549
 dc.l 543
 dc.l 536
 dc.l 530
 dc.l 524
 dc.l 517
 dc.l 512
 dc.l 506
 dc.l 500
 dc.l 495
 dc.l 489
 dc.l 484
 dc.l 479
 dc.l 474
 dc.l 469
 dc.l 464
 dc.l 459
 dc.l 454
 dc.l 450
 dc.l 445
 dc.l 441
 dc.l 437
 dc.l 432
 dc.l 428
 dc.l 424
 dc.l 420
 dc.l 416
 dc.l 412
 dc.l 409
 dc.l 405
 dc.l 401
 dc.l 398
 dc.l 394
 dc.l 391
 dc.l 387
 dc.l 384
 dc.l 381
 dc.l 378
 dc.l 374
 dc.l 371
 dc.l 368
 dc.l 365
 dc.l 362
 dc.l 359
 dc.l 357
 dc.l 354
 dc.l 351
 dc.l 348
 dc.l 345
 dc.l 343
 dc.l 340
 dc.l 338
 dc.l 335
 dc.l 333
 dc.l 330
 dc.l 328
 dc.l 325
 dc.l 323
 dc.l 321
 dc.l 318
 dc.l 316
 dc.l 314
 dc.l 312
 dc.l 310
 dc.l 307
 dc.l 305
 dc.l 303
 dc.l 301
 dc.l 299
 dc.l 297
 dc.l 295
 dc.l 293
 dc.l 291
 dc.l 290
 dc.l 288
 dc.l 286
 dc.l 284
 dc.l 282
 dc.l 280
 dc.l 279
 dc.l 277
 dc.l 275
 dc.l 274
 dc.l 272
 dc.l 270
 dc.l 269
 dc.l 267
 dc.l 265
 dc.l 264
 dc.l 262
 dc.l 261
 dc.l 259
 dc.l 258
 dc.l 256
 dc.l 255
 dc.l 253
 dc.l 252
 dc.l 251
 dc.l 249
 dc.l 248
 dc.l 246
 dc.l 245
 dc.l 244
 dc.l 242
 dc.l 241
 dc.l 240
 dc.l 238
 dc.l 237
 dc.l 236
 dc.l 235
 dc.l 233
 dc.l 232
 dc.l 231
 dc.l 230
 dc.l 229
 dc.l 228
 dc.l 226
 dc.l 225
 dc.l 224
 dc.l 223
 dc.l 222
 dc.l 221
 dc.l 220
 dc.l 219
 dc.l 218
 dc.l 216
 dc.l 215
 dc.l 214
 dc.l 213
 dc.l 212
 dc.l 211
 dc.l 210
 dc.l 209
 dc.l 208
 dc.l 207
 dc.l 206
 dc.l 206
 dc.l 205
 dc.l 204
 dc.l 203
 dc.l 202
 dc.l 201
 dc.l 200
 dc.l 199
 dc.l 198
 dc.l 197
 dc.l 196
 dc.l 196
 dc.l 195
 dc.l 194
 dc.l 193
 dc.l 192
 dc.l 191
 dc.l 191
 dc.l 190
 dc.l 189
 dc.l 188
 dc.l 187
 dc.l 187
 dc.l 186
 dc.l 185
 dc.l 184
 dc.l 184
 dc.l 183
 dc.l 182
 dc.l 181
 dc.l 181
 dc.l 180
 dc.l 179
 dc.l 178
 dc.l 178
 dc.l 177
 dc.l 176
 dc.l 176
 dc.l 175
 dc.l 174
 dc.l 174
 dc.l 173
 dc.l 172
 dc.l 172
 dc.l 171
 dc.l 170
 dc.l 170
 dc.l 169
 dc.l 168
 dc.l 168
 dc.l 167
 dc.l 166
 dc.l 166
 dc.l 165
 dc.l 165
 dc.l 164
 dc.l 163
 dc.l 163
 dc.l 162
 dc.l 162
 dc.l 161
 dc.l 160
 dc.l 160
 dc.l 159
 dc.l 159
 dc.l 158
 dc.l 158
 dc.l 157
 dc.l 156
 dc.l 156
 dc.l 155
 dc.l 155
 dc.l 154
 dc.l 154
 dc.l 153
 dc.l 153
 dc.l 152
 dc.l 152
 dc.l 151
 dc.l 151
 dc.l 150
 dc.l 150
 dc.l 149
 dc.l 149
 dc.l 148
 dc.l 148
 dc.l 147
 dc.l 147
 dc.l 146
 dc.l 146
 dc.l 145
 dc.l 145
 dc.l 144
 dc.l 144
 dc.l 143
 dc.l 143
 dc.l 142
 dc.l 142
 dc.l 142
 dc.l 141
 dc.l 141
 dc.l 140
 dc.l 140
 dc.l 139
 dc.l 139
 dc.l 138
 dc.l 138
 dc.l 138
 dc.l 137
 dc.l 137
 dc.l 136
 dc.l 136
 dc.l 136
 dc.l 135
 dc.l 135
 dc.l 134
 dc.l 134
 dc.l 133
 dc.l 133
 dc.l 133
 dc.l 132
 dc.l 132
 dc.l 132
 dc.l 131
 dc.l 131
 dc.l 130
 dc.l 130
 dc.l 130
 dc.l 129
 dc.l 129
 dc.l 128
 dc.l 128
 dc.l 128
 dc.l 127
 dc.l 127
 dc.l 127
 dc.l 126
 dc.l 126
 dc.l 126
 dc.l 125
 dc.l 125
 dc.l 125
 dc.l 124
 dc.l 124
 dc.l 123
 dc.l 123
 dc.l 123
 dc.l 122
 dc.l 122
 dc.l 122
 dc.l 121
 dc.l 121
 dc.l 121
 dc.l 120
 dc.l 120
 dc.l 120
 dc.l 119
 dc.l 119
 dc.l 119
 dc.l 119
 dc.l 118
 dc.l 118
 dc.l 118
 dc.l 117
 dc.l 117
 dc.l 117
 dc.l 116
 dc.l 116
 dc.l 116
 dc.l 115
 dc.l 115
 dc.l 115
 dc.l 115
 dc.l 114
 dc.l 114
 dc.l 114
 dc.l 113
 dc.l 113
 dc.l 113
 dc.l 113
 dc.l 112
 dc.l 112
 dc.l 112
 dc.l 111
 dc.l 111
 dc.l 111
 dc.l 111
 dc.l 110
 dc.l 110
 dc.l 110
 dc.l 109
 dc.l 109
 dc.l 109
 dc.l 109
 dc.l 108
 dc.l 108
 dc.l 108
 dc.l 108
 dc.l 107
 dc.l 107
 dc.l 107
 dc.l 107
 dc.l 106
 dc.l 106
 dc.l 106
 dc.l 106
 dc.l 105
 dc.l 105
 dc.l 105
 dc.l 105
 dc.l 104
 dc.l 104
 dc.l 104
 dc.l 104
 dc.l 103
 dc.l 103
 dc.l 103
 dc.l 103
 dc.l 102
 dc.l 102
 dc.l 102
 dc.l 102
 dc.l 101
 dc.l 101
 dc.l 101
 dc.l 101
 dc.l 101
 dc.l 100
 dc.l 100
 dc.l 100
 dc.l 100
 dc.l 99
 dc.l 99
 dc.l 99
 dc.l 99
 dc.l 99
 dc.l 98
 dc.l 98
 dc.l 98
 dc.l 98
 dc.l 97
 dc.l 97
 dc.l 97
 dc.l 97
 dc.l 97
 dc.l 96
 dc.l 96
 dc.l 96
 dc.l 96
 dc.l 96
 dc.l 95
 dc.l 95
 dc.l 95
 dc.l 95
 dc.l 95
 dc.l 94
 dc.l 94
 dc.l 94
 dc.l 94
 dc.l 94
 dc.l 93
 dc.l 93
 dc.l 93
 dc.l 93
 dc.l 93
 dc.l 92
 dc.l 92
 dc.l 92
 dc.l 92
 dc.l 92
 dc.l 91
 dc.l 91
 dc.l 91
 dc.l 91
 dc.l 91
 dc.l 91
 dc.l 90
 dc.l 90
 dc.l 90
 dc.l 90
 dc.l 90
 dc.l 89
 dc.l 89
 dc.l 89
 dc.l 89
 dc.l 89
 dc.l 89
 dc.l 88
 dc.l 88
 dc.l 88
 dc.l 88
 dc.l 88
 dc.l 87
 dc.l 87
 dc.l 87
 dc.l 87
 dc.l 87
 dc.l 87
 dc.l 86
 dc.l 86
 dc.l 86
 dc.l 86
 dc.l 86
 dc.l 86
 dc.l 85
 dc.l 85
 dc.l 85
 dc.l 85
 dc.l 85
 dc.l 85
 dc.l 84
 dc.l 84
 dc.l 84
 dc.l 84
 dc.l 84
 dc.l 84
 dc.l 84
 dc.l 83
 dc.l 83
 dc.l 83
 dc.l 83
 dc.l 83
 dc.l 83
 dc.l 82
 dc.l 82
 dc.l 82
 dc.l 82
 dc.l 82
 dc.l 82
 dc.l 82
 dc.l 81
 dc.l 81
 dc.l 81
 dc.l 81
 dc.l 81
 dc.l 81
 dc.l 80
 dc.l 80
 dc.l 80
 dc.l 80
 dc.l 80
 dc.l 80
 dc.l 80
 dc.l 79
 dc.l 79
 dc.l 79
 dc.l 79
 dc.l 79
 dc.l 79
 dc.l 79
 dc.l 78
 dc.l 78
 dc.l 78
 dc.l 78
 dc.l 78
 dc.l 78
 dc.l 78
 dc.l 78
 dc.l 77
 dc.l 77
 dc.l 77
 dc.l 77
 dc.l 77
 dc.l 77
 dc.l 77
 dc.l 76
 dc.l 76
 dc.l 76
 dc.l 76
 dc.l 76
 dc.l 76
 dc.l 76
 dc.l 76
 dc.l 75
 dc.l 75
 dc.l 75
 dc.l 75
 dc.l 75
 dc.l 75
 dc.l 75
 dc.l 75
 dc.l 74
 dc.l 74
 dc.l 74
 dc.l 74
 dc.l 74
 dc.l 74
 dc.l 74
 dc.l 74
 dc.l 73
 dc.l 73
 dc.l 73
 dc.l 73
 dc.l 73
 dc.l 73
 dc.l 73
 dc.l 73
 dc.l 72
 dc.l 72
 dc.l 72
 dc.l 72
 dc.l 72
 dc.l 72
 dc.l 72
 dc.l 72
 dc.l 72
 dc.l 71
 dc.l 71
 dc.l 71
 dc.l 71
 dc.l 71
 dc.l 71
 dc.l 71
 dc.l 71
 dc.l 70
 dc.l 70
 dc.l 70
 dc.l 70
 dc.l 70
 dc.l 70
 dc.l 70
 dc.l 70
 dc.l 70
 dc.l 69
 dc.l 69
 dc.l 69
 dc.l 69
 dc.l 69
 dc.l 69
 dc.l 69
 dc.l 69
 dc.l 69
 dc.l 69
 dc.l 68
 dc.l 68
 dc.l 68
 dc.l 68
 dc.l 68
 dc.l 68
 dc.l 68
 dc.l 68
 dc.l 68
 dc.l 67
 dc.l 67
 dc.l 67
 dc.l 67
 dc.l 67
 dc.l 67
 dc.l 67
 dc.l 67
 dc.l 67
 dc.l 67
 dc.l 66
 dc.l 66
 dc.l 66
 dc.l 66
 dc.l 66
 dc.l 66
 dc.l 66
 dc.l 66
 dc.l 66
 dc.l 66
 dc.l 65
 dc.l 65
 dc.l 65
 dc.l 65
 dc.l 65
 dc.l 65
 dc.l 65
 dc.l 65
 dc.l 65
 dc.l 65
 dc.l 65
 dc.l 64
 dc.l 64
 dc.l 64
 dc.l 64
 dc.l 64
 dc.l 64
 dc.l 64
 dc.l 64
 dc.l 64
 dc.l 64
 dc.l 64
 dc.l 63
 dc.l 63
 dc.l 63
 dc.l 63
 dc.l 63
 dc.l 63
 dc.l 63
 dc.l 63
 dc.l 63
 dc.l 63
 dc.l 63
 dc.l 62
 dc.l 62
 dc.l 62
 dc.l 62
 dc.l 62
 dc.l 62
 dc.l 62
 dc.l 62
 dc.l 62
 dc.l 62
 dc.l 62
 dc.l 61
 dc.l 61
 dc.l 61
 dc.l 61
 dc.l 61
 dc.l 61
 dc.l 61
 dc.l 61
 dc.l 61
 dc.l 61
 dc.l 61
 dc.l 61
 dc.l 60
 dc.l 60
 dc.l 60
 dc.l 60
 dc.l 60
 dc.l 60
 dc.l 60
 dc.l 60
 dc.l 60
 dc.l 60
 dc.l 60
 dc.l 60
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43


		include "data/mars_sdram.asm"

; ====================================================================
; ----------------------------------------------------------------
; MARS SH2 RAM
; ----------------------------------------------------------------

SH2_RAM:
		struct SH2_RAM
	if MOMPASS=1
MarsRam_System	ds.l 0
MarsRam_Video	ds.l 0
MarsRam_Sound	ds.l 0
sizeof_marsram	ds.l 0
	else
MarsRam_System	ds.b (sizeof_marssys-MarsRam_System)
MarsRam_Video	ds.b (sizeof_marsvid-MarsRam_Video)
MarsRam_Sound	ds.b (sizeof_marssnd-MarsRam_Sound)
sizeof_marsram	ds.l 0
	endif

.here:
	if MOMPASS=7
		message "MARS RAM from \{((SH2_RAM)&$FFFFFF)} to \{((.here)&$FFFFFF)}"
	endif
		finish
		
; ====================================================================
; ----------------------------------------------------------------
; MARS System RAM
; ----------------------------------------------------------------

			struct MarsRam_System
MarsSys_Input		ds.l 4
MARSSys_MdReq		ds.l 1
sizeof_marssys		ds.l 0
			finish
		
; ====================================================================
; ----------------------------------------------------------------
; MARS Sound RAM
; ----------------------------------------------------------------

			struct MarsRam_Sound
MARSSnd_Pwm		ds.b sizeof_sndchn*8
sizeof_marssnd		ds.l 0
			finish

; ====================================================================
; ----------------------------------------------------------------
; MARS Video RAM
; ----------------------------------------------------------------

			struct MarsRam_Video
RAM_Mars_Global		ds.w sizeof_MarsGbl		; Note: keep it as a word
RAM_Mars_Palette	ds.w 256
RAM_Mars_DivTable	ds.l MAX_DIVTABLE
RAM_Mars_PerspTable	ds.w MAX_PERSP
RAM_Mars_PlgnList_0	ds.l MAX_FACES			; Pointer list(s)
RAM_Mars_PlgnList_1	ds.l MAX_FACES
RAM_Mars_Plgn_ZList	ds.l MAX_FACES*2		; Z value / foward faces | backward faces
RAM_Mars_PlgnNum_0	ds.w 1
RAM_Mars_PlgnNum_1	ds.w 1
RAM_Mars_ObjCamera	ds.b sizeof_camera*4
RAM_Mars_Objects	ds.b sizeof_mdlobj*64
RAM_Mars_Polygons_0	ds.b sizeof_polygn*MAX_FACES	; Polygon list 0
RAM_Mars_Polygons_1	ds.b sizeof_polygn*MAX_FACES	; Polygon list 1
RAM_Mars_VdpDrwList	ds.b sizeof_plypz*MAX_SVDP_PZ
RAM_Mars_VdpDrwList_e	ds.l 0
sizeof_marsvid		ds.l 0
			finish
