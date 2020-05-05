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

		mov.w	@(marsGbl_MdlFacesCntr,gbr),r0
		cmp/eq	#0,r0
		bt	.z_end
		mov	#2,r11
		cmp/ge	r11,r0
		bt	.z_normal

		bra	.z_end
		nop
.z_normal:
		mov	#MAX_FACES,r11
		cmp/ge	r11,r0
		bf	.z_ranout
		mov	r11,r0
.z_ranout:
		mov	#RAM_Mars_Plgn_ZList,r12
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
; persp_table:	binclude "system/mars/data/perspdata.bin"
; 		align 4

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
