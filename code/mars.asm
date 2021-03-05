; ====================================================================		
; ----------------------------------------------------------------
; MARS SH2 Section
; 
; CODE for both CPUs
; RAM and some DATA go here
; ----------------------------------------------------------------

		phase CS3		; now we are at SDRAM
		cpu SH7600		; should be SH7095 but ASL doesn't have it, this is close enough

; ====================================================================

		include "system/mars/head.asm"

; ====================================================================
; ----------------------------------------------------------------
; MARS Global variables (for gbr)
; 
; Shared for both CPUs
; ----------------------------------------------------------------

			struct 0
marsGbl_PlyPzList_R	ds.l 1		; Current graphic piece to draw
marsGbl_PlyPzList_W	ds.l 1		; Current graphic piece to write
marsGbl_CurrZList	ds.l 1		; Current Zsort entry
marsGbl_CurrFacePos	ds.l 1		; Current top face of the list while reading model data
marsGbl_MdTaskList_Sw	ds.w 1		; Requests from Genesis FIFO reading point
marsGbl_MdTaskList_Rq	ds.w 1		; and writing point
marsGbl_MdlFacesCntr	ds.w 1		; And the number of faces stored on that list
marsGbl_PolyBuffNum	ds.w 1		; PolygonBuffer switch: READ/WRITE or WRITE/READ
marsGbl_PzListCntr	ds.w 1		; Number of graphic pieces to draw
marsGbl_DrwTask		ds.w 1		; Current Drawing task for Watchdog
marsGbl_VIntFlag_M	ds.w 1		; Sets to 0 if VBlank finished on Master CPU
marsGbl_VIntFlag_S	ds.w 1		; Same thing but for the Slave CPU
marsGbl_DivReq_M	ds.w 1		; Flag to tell Watchdog we are in the middle of division
marsGbl_CurrFb		ds.w 1		; Current framebuffer number
marsGbl_PalDmaMidWr	ds.w 1		; Enable this flag if modifing RAM_Mars_Palette
marsGbl_ZSortReq	ds.w 1		; Flag to request Zsort in Slave's watchdogd
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
		sts	pr,@-r15
		mov	#MarsSound_ReadPwm,r0
		jsr	@r0
		nop
		lds	@r15+,pr
.exit:		mov	#_FRT,r1
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
; Master | CMD Interrupt (MD request)
; ------------------------------------------------

m_irq_cmd:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+cmdintclr,r1
		mov.w	r0,@r1
		
		mov	r2,@-r15
		mov	r3,@-r15
		stc	sr,@-r15
		mov	#$F0,r0
		ldc	r0,sr
		mov	#RAM_Mars_MdTasksFifo_M,r2
		mov	#_sysreg+comm8,r1
.next_comm:
		mov	#2,r0		; SH is ready
		mov.b	r0,@(1,r1)
.wait_md_b:
		mov.b	@(0,r1),r0	; get MD status
		and	#$FF,r0
		tst	r0,r0
		bt	.finish
		cmp/eq	#1,r0		; MD is writing?
		bf	.wait_md_b
		mov	#1,r0		; SH is busy
		mov.b	r0,@(1,r1)
.wait_md_c:
		mov.b	@(0,r1),r0
		and	#$FF,r0
		tst	r0,r0
		bt	.finish
		cmp/eq	#2,r0		; MD is ready?
		bf	.wait_md_c
		mov.w	@(2,r1),r0	; comm10
		mov.w	r0,@r2
		mov.w	@(4,r1),r0	; comm12
		mov.w	r0,@(2,r2)
		
; 		mov	#_sysreg+comm6,r4
; 		mov.w	@r4,r0
; 		add	#1,r0
; 		mov.w	r0,@r4
		mov	#2,r0		; SH is ready
		mov.b	r0,@(1,r1)
		bra	.next_comm
		add	#4,r2
.finish:
		mov	#_sysreg+comm14,r1
		mov.b	@r1,r0
		or	#$80,r0
		mov.b	r0,@r1
		ldc 	@r15+,sr
		mov 	@r15+,r3
		mov 	@r15+,r2
		rts
		nop
		align 4

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
		mov	#_FRT,r1
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
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+vintclr,r1
		mov.w	r0,@r1

	; TODO: DMA works but after the first
	; pass it locks both SOURCE and DESTINATION
	; data sections
		mov	#_vdpreg,r1			; Wait for palette access ok
.wait		mov.b	@(vdpsts,r1),r0
		tst	#$20,r0
		bt	.wait
		stc	sr,@-r15
		mov	r2,@-r15
		mov	r3,@-r15
; 		mov	r4,@-r15
; 		mov	r5,@-r15
; 		mov	r6,@-r15
		mov	#$F0,r0
		ldc	r0,sr
		mov	#RAM_Mars_Palette,r1		; Send palette stored on RAM		
		mov	#_palette,r2
 		mov	#256/16,r3		
.copy_pal:
	rept 16
		mov.w	@r1+,r0
		mov.w	r0,@r2
		add	#2,r2
	endm
		dt	r3
		bf	.copy_pal

; 		mov	#RAM_Mars_Palette,r1		; Send palette stored on RAM
; 		mov	#_palette,r2
;  		mov	#256,r3
; 		mov	#%0101011011110001,r4		; transfer size 2 / burst
; 		mov	#_DMASOURCE0,r5 		; _DMASOURCE = $ffffff80
; 		mov	#_DMAOPERATION,r6 		; _DMAOPERATION = $ffffffb0
; 		mov	r1,@r5				; set source address
; 		mov	r2,@(4,r5)			; set destination address
; 		mov	r3,@(8,r5)			; set length
; 		xor	r0,r0
; 		mov	r0,@r6				; Stop OPERATION
; 		xor	r0,r0
; 		mov	r0,@($C,r5)			; clear TE bit
; 		mov	r4,@($C,r5)			; load mode
; 		add	#1,r0
; 		mov	r0,@r6				; Start OPERATION
; 		mov	@r15+,r6
; 		mov	@r15+,r5
; 		mov	@r15+,r4
		mov	@r15+,r3
		mov	@r15+,r2
		ldc	@r15+,sr
		
.mid_pwrite:
		mov 	#0,r0				; Clear VintFlag for Master
		mov.w	r0,@(marsGbl_VIntFlag_M,gbr)
		rts
		nop
		align 4
		
; =================================================================
; ------------------------------------------------
; Master | VRES Interrupt (Pressed RESET on Genesis)
; ------------------------------------------------

m_irq_vres:
		mov.l	#_sysreg,r0
		ldc	r0,gbr
		mov.w	r0,@(vresintclr,gbr)	; V interrupt clear
		nop
		nop
		nop
		nop
		mov	#$F0,r0
		ldc	r0,sr
		mov.b	@(dreqctl,gbr),r0
		tst	#1,r0
		bf	.mars_reset
.md_reset:
		mov.l	#"68UP",r1		; wait for the 68K to show up
		mov.l	@(comm12,gbr),r0
		cmp/eq	r0,r1
		bf	.md_reset
.sh_wait:
		mov.l	#"S_OK",r1		; wait for the Slave CPU to show up
		mov.l	@(comm4,gbr),r0
		cmp/eq	r0,r1
		bf	.sh_wait
		mov.l	#"M_OK",r0		; let the others know master ready
		mov.l	r0,@(comm0,gbr)
		mov.l	#CS3|$40000-8,r15	; Set reset values
		mov.l	#SH2_M_HotStart,r0
		mov.l	r0,@r15
		mov.w	#$F0,r0
		mov.l	r0,@(4,r15)
		mov.l	#_DMAOPERATION,r1
		mov.l	#0,r0
		mov.l	r0,@r1			; Turn any DMA tasks OFF
		mov.l	#_DMACHANNEL0,r1
		mov.l	#0,r0
		mov.l	r0,@r1
		mov.l	#%0100010011100000,r1
		mov.l	r0,@r1			; Channel control
		rte
		nop
.mars_reset:
		mov	#_FRT,r1
		mov.b	@(_TOCR,r1),r0
		or	#$01,r0
		mov.b	r0,@(_TOCR,r1)
.vresloop:
		bra	.vresloop
		nop
		align 4
		ltorg				; Save MASTER IRQ literals here

; =================================================================
; ------------------------------------------------
; Master | Watchdog interrupt
; ------------------------------------------------

; m_irq_custom:
; see video.asm

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
		mov	#_FRT,r1
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
; 
; Process request from MD
; ------------------------------------------------

s_irq_cmd:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+cmdintclr,r1
		mov.w	r0,@r1

		mov	r2,@-r15
		mov	r3,@-r15
; 		mov	r4,@-r15
		mov	#RAM_Mars_MdTasksFifo_S,r2
		mov	#_sysreg+comm8,r1
.next_comm:
		mov	#2,r0		; SH is ready
		mov.b	r0,@(1,r1)
.wait_md_b:
		mov.b	@(0,r1),r0	; get MD status
		and	#$FF,r0
		tst	r0,r0
		bt	.finish
		cmp/eq	#1,r0		; MD is writing?
		bf	.wait_md_b
		mov	#1,r0		; SH is busy
		mov.b	r0,@(1,r1)
.wait_md_c:
		mov.b	@(0,r1),r0
		and	#$FF,r0
		tst	r0,r0
		bt	.finish
		cmp/eq	#2,r0		; MD is ready?
		bf	.wait_md_c
		mov.w	@(2,r1),r0	; comm10
		mov.w	r0,@r2
		mov.w	@(4,r1),r0	; comm12
		mov.w	r0,@(2,r2)
		
; 		mov	#_sysreg+comm6,r4
; 		mov.w	@r4,r0
; 		add	#1,r0
; 		mov.w	r0,@r4
		mov	#2,r0		; SH is ready
		mov.b	r0,@(1,r1)
		bra	.next_comm
		add	#4,r2
.finish:
		mov	#_sysreg+comm15,r1
		mov.b	@r1,r0
		or	#$80,r0
		mov.b	r0,@r1
; 		mov 	@r15+,r4		
		mov 	@r15+,r3
		mov 	@r15+,r2
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
		mov	#_FRT,r1
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
		mov 	#0,r0				; Clear VintFlag for Slave
		mov.w	r0,@(marsGbl_VIntFlag_S,gbr)
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+vintclr,r1
		rts
		mov.w	r0,@r1
		align 4

; =================================================================
; ------------------------------------------------
; Slave | VRES Interrupt (Pressed RESET on Genesis)
; ------------------------------------------------

s_irq_vres:
		mov.l	#_sysreg,r0
		ldc	r0,gbr
		mov.w	r0,@(vresintclr,gbr)	; V interrupt clear
		nop
		nop
		nop
		nop
		mov	#$F0,r0
		ldc	r0,sr
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
		mov	#_FRT,r1
		mov.b	@(_TOCR,r1),r0
		or	#$01,r0
		mov.b	r0,@(_TOCR,r1)
.vresloop:
		bra	.vresloop
		nop
		align 4
		ltorg			; Save Slave IRQ literals

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
		mov	#CS3|$40000,r15			; Set default Stack for Master
		mov	#_FRT,r1
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
		mov.l   #$FFFFFEE2,r0			; Pre-init special interrupt
		mov     #$50,r1
		mov.w   r1,@r0
		mov.l   #$FFFFFEE4,r0
		mov     #$120/4,r1			; VBR + this/4
		shll8   r1
		mov.w   r1,@r0

; ------------------------------------------------
; Wait for Genesis and Slave CPU
; ------------------------------------------------

.wait_md:
		mov 	#_sysreg+comm0,r2		; Wait for Genesis
		mov.l	@r2,r0
		cmp/eq	#0,r0
		bf	.wait_md
		mov.l	#"SLAV",r1
.wait_slave:
		mov.l	@(8,r2),r0			; Wait for Slave CPU to finish booting
		cmp/eq	r1,r0
		bf	.wait_slave
		mov.l	#0,r0				; clear "SLAV"
		mov.l	r0,@(8,r2)
		mov.l	r0,@r2
		
; ====================================================================
; ----------------------------------------------------------------
; Master main code
; 
; This CPU is exclusively used for drawing polygons, to interact
; with models use the Slave CPU instead.
; ----------------------------------------------------------------

SH2_M_HotStart:
		mov	#CS3|$40000,r15				; Stack again if coming from RESET
		mov	#RAM_Mars_Global,r14			; GBR - Global values/variables
		ldc	r14,gbr
		mov	#$F0,r0					; Interrupts OFF
		ldc	r0,sr
		mov	#_CCR,r1
		mov	#0,r0					; Cache OFF
		mov.w	r0,@r1
		mov	#%00011001,r0				; Cache purge / Two-way mode / Cache ON
		mov.w	r0,@r1
		mov	#_sysreg,r1
		mov	#VIRQ_ON|CMDIRQ_ON|PWMIRQ_ON,r0		; Enable these interrupts		
    		mov.b	r0,@(intmask,r1)
		mov 	#CACHE_MASTER,r1			; Load 3D Routines on CACHE	
		mov 	#$C0000000,r2				; Those run more faster here supposedly...
		mov 	#(CACHE_MASTER_E-CACHE_MASTER)/4,r3
.copy:
		mov 	@r1+,r0
		mov 	r0,@r2
		add 	#4,r2
		dt	r3
		bf	.copy
		
; ------------------------------------------------

		mov	#MarsVideo_Init,r0		; Init Video
		jsr	@r0
		nop
		bsr	MarsSound_Init			; Init Sound
		nop
		
; ------------------------------------------------

		mov	#_CCR,r1
		mov	#%00001000,r0		; Two-way mode
		mov.w	r0,@r1
		mov	#%00011001,r0		; Cache purge / Two-way mode / Cache ON
		mov.w	r0,@r1
		mov.l	#$20,r0			; Interrupts ON
		ldc	r0,sr

; --------------------------------------------------------
; Loop
; --------------------------------------------------------

master_loop:
		mov	#_sysreg+comm0,r4	; DEBUG COUNTER
		mov.w	@r4,r0
		add	#1,r0
		mov.w	r0,@r4

		mov	#_sysreg+comm14,r1
		mov.b	@r1,r0			; Any request from Slave?
		mov	r0,r2
		and 	#$80,r0
		cmp/eq	#0,r0
		bf	.md_req
		mov	r2,r0
		and	#$7F,r0
		shll2	r0
		mov	#.list,r1
		mov	@(r1,r0),r0
		jmp	@r0
		nop
		align 4

; ------------------------------------------------
; Graphic processing list for Master
; ------------------------------------------------

.list:
		dc.l master_loop
		dc.l .draw_objects
		dc.l master_loop

; ------------------------------------------------
; Process Visual/Audio requests from Genesis
; ------------------------------------------------

.md_req:
		stc	sr,@-r15
		mov	#$F0,r0
		ldc	r0,sr
		mov	#MAX_MDTASKS,r13
		mov	#RAM_Mars_MdTasksFifo_M,r14
.next_req:
		mov	r13,@-r15
		mov	@r14,r0
		cmp/eq	#0,r0
		bt	.no_task
		jsr	@r0
		nop
		xor	r0,r0
		mov	r0,@r14
.no_task:
		mov	#MAX_MDTSKARG*4,r0
		mov	@r15+,r13
		dt	r13
		bf/s	.next_req
		add	r0,r14
		mov	#_sysreg+comm14,r1
		mov.b	@r1,r0
		and	#$7F,r0
		mov.b	r0,@r1
		ldc 	@r15+,sr
		bra	master_loop
		nop

; --------------------------------------------------------
; Start building and drawing polygons
; --------------------------------------------------------

.draw_objects:
		mov	#$FFFFFE92,r0
		mov	#8,r1
		mov.b	r1,@r0
		mov	#$19,r1
		mov.b	r1,@r0
		mov	#MarsVideo_SetWatchdog,r0
		jsr	@r0
		nop
		mov.w   @(marsGbl_PolyBuffNum,gbr),r0	; Start drawing polygons from the READ buffer
		tst     #1,r0				; Check for which buffer to use
		bt	.page_2
		mov 	#RAM_Mars_PlgnList_0,r14
		mov	#RAM_Mars_PlgnNum_0,r13
		bra	.cont_plgn
		nop
.page_2:
		mov 	#RAM_Mars_PlgnList_1,r14
		mov	#RAM_Mars_PlgnNum_1,r13
.cont_plgn:

	; While we are doing this, the watchdog is
	; working on the background drawing the polygons
	; using the "pieces" list
	; 
	; r14 - Polygon pointers list
	; r13 - Number of polygons to build
		mov.w	@r13,r13
		cmp/pl	r13
		bf	.skip
.loop:
		mov	r14,@-r15
		mov	r13,@-r15
		mov	@r14,r14			; Get location of the polygon
		cmp/pl	r14
		bf	.invalid
		mov 	#MarsVideo_MakePolygon,r0
		jsr	@r0
		nop
.invalid:
		mov	@r15+,r13
		mov	@r15+,r14
		dt	r13
		bf/s	.loop
		add	#4,r14
.skip:

	; --------------------------------------
.wait_pz: 	mov.w	@(marsGbl_PzListCntr,gbr),r0	; Any pieces remaining on interrupt?
		cmp/eq	#0,r0
		bf	.wait_pz
.wait_task:	mov.w	@(marsGbl_DrwTask,gbr),r0	; Any draw task active?
		cmp/eq	#0,r0
		bf	.wait_task
		mov.l   #$FFFFFE80,r1			; Stop watchdog
		mov.w   #$A518,r0
		mov.w   r0,@r1
		mov	#_vdpreg,r1			; Framebuffer swap request
		mov.b	@(framectl,r1),r0		; watchdog will check for it later
		xor	#1,r0
		mov.b	r0,@(framectl,r1)
		mov.b	r0,@(marsGbl_CurrFb,gbr)

	; --------------------
	; DEBUG counter
; 		mov	#_sysreg+comm4,r1
; 		mov.w	@r1,r0
; 		add	#1,r0
; 		mov.w	r0,@r1
	; --------------------
	
		mov	#_sysreg+comm14,r1
		mov.b	@r1,r0
		and	#$80,r0
		mov.b	r0,@r1
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
		mov	#_sysreg,r14
		ldc	r14,gbr
		mov	#_FRT,r1
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

		mov	#$FFFFFE80,r1
		mov.w	#$5A7F,r0			; Watchdog wait timer
		mov.w	r0,@r1
		mov.w	#$A538,r0			; Watchdog ON
		mov.w	r0,@r1
		
; ====================================================================
; ----------------------------------------------------------------
; Slave main code
; ----------------------------------------------------------------

SH2_S_HotStart:
		mov.l	#CS3|$3F000,r15			; Reset stack
		mov.l	#RAM_Mars_Global,r14		; Reset gbr
		ldc	r14,gbr
		mov.l	#$F0,r0				; Interrupts OFF
		ldc	r0,sr
		mov.l	#_CCR,r1
		mov	#0,r0				; Cache OFF
		mov.w	r0,@r1
		mov	#%00011001,r0			; Cache purge / Two-way mode / Cache ON
		mov.w	r0,@r1
		mov	#_sysreg,r1
		mov	#VIRQ_ON|CMDIRQ_ON,r0		; Enable these interrupts		
    		mov.b	r0,@(intmask,r1)
		mov 	#CACHE_SLAVE,r1			; Load 3D Routines on CACHE	
		mov 	#$C0000000,r2			; Those run more faster here supposedly...
		mov 	#(CACHE_SLAVE_E-CACHE_SLAVE)/4,r3
.copy:
		mov 	@r1+,r0
		mov 	r0,@r2
		add 	#4,r2
		dt	r3
		bf	.copy

; ------------------------------------------------
; REMINDER: In blender, 1 meter = $10000
;
		mov	#MarsMdl_Init,r0
		jsr	@r0
		nop
		
; ------------------------------------------------

		mov	#_CCR,r1
		mov	#%00001000,r0			; Two-way mode
		mov.w	r0,@r1
		mov	#%00011001,r0			; Cache purge / Two-way mode / Cache ON
		mov.w	r0,@r1
		mov.l	#$20,r0				; Interrupts ON
		ldc	r0,sr
		
; --------------------------------------------------------
; Loop
; --------------------------------------------------------

slave_loop:

; ------------------------------------------------
; Process tasks other than visual or sound,
; ex. object interaction or move the 3d camera
; ------------------------------------------------

		mov	#_sysreg+comm15,r1
		mov.b	@r1,r0
		and	#$80,r0
		cmp/eq	#0,r0
		bt	.no_req
		mov	#MAX_MDTASKS,r13
		mov	#RAM_Mars_MdTasksFifo_S,r14
.next_req:
		mov	r13,@-r15
		mov	@r14,r0
		cmp/eq	#0,r0
		bt	.no_task
		jsr	@r0
		nop
		xor	r0,r0
		mov	r0,@r14
.no_task:
		mov	#MAX_MDTSKARG*4,r0
		mov	@r15+,r13
		dt	r13
		bf/s	.next_req
		add	r0,r14
		mov	#_sysreg+comm15,r1
		mov.b	@r1,r0
		and	#$7F,r0
		mov.b	r0,@r1
.no_req:
		mov	#_sysreg+comm2,r4		; DEBUG COUNTER
		mov.w	@r4,r0
		add	#1,r0
		mov.w	r0,@r4
		
; --------------------------------------------------------
; Start building polygons from models
; 
; CAMERA ANIMATION IS DONE ON THE 68K
; --------------------------------------------------------

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

; ----------------------------------------

		mov	#MarsLay_Read,r0		; Build layout inside camera
		jsr	@r0				; takes 9 object slots
		nop
		mov	#RAM_Mars_Objects,r14		; Build all objects
		mov	#MAX_MODELS,r13
.loop:
		mov	@(mdl_data,r14),r0		; Object model data == 0 or -1?
		cmp/pl	r0
		bf	.invlid
		mov	r13,@-r15
		mov	#MarsMdl_ReadModel,r0
		jsr	@r0
		nop
		mov	@r15+,r13
.invlid:
		dt	r13
		bf/s	.loop
		add	#sizeof_mdlobj,r14
.skip:

; ----------------------------------------

		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
		tst     #1,r0
		bf	.page_2
		mov 	#RAM_Mars_PlgnList_0,r14
		mov 	#RAM_Mars_PlgnNum_0,r13
		bra	.swap_now
		nop
.page_2:
		mov 	#RAM_Mars_PlgnList_1,r14
		mov 	#RAM_Mars_PlgnNum_1,r13
.swap_now:
		bsr	slv_sort_z
		nop

; ----------------------------------------

		mov.l	#_sysreg+comm14,r1		; Master CPU still drawing pieces?
.mstr_busy:
		mov.b	@r1,r0
		and	#$7F,r0
		cmp/eq	#0,r0
		bf	slave_loop			; Skip frame
		mov.w	@(marsGbl_PolyBuffNum,gbr),r0	; Swap polygon buffer
 		xor	#1,r0
 		mov.w	r0,@(marsGbl_PolyBuffNum,gbr)
		mov	#_sysreg+comm14,r2
 		mov	#1,r1				; Set task $01 to Master
		mov.b	@r2,r0
		and	#$80,r0
		or	r1,r0
		mov.b	r0,@r2
		bra	slave_loop
		nop
		align 4
		ltorg

; --------------------------------------------------------
; Sort all faces in the current buffer
; 
; r14 - Polygon list
; r13 - Number of polygons processed
; --------------------------------------------------------

; Bubble sorting

slv_sort_z:
		sts	pr,@-r15
		mov	#0,r0					; Reset current PlgnNum
		mov.w	r0,@r13
		mov	#RAM_Mars_Plgn_ZList,r12	
		mov	#2,r11
		mov.w	@(marsGbl_MdlFacesCntr,gbr),r0		; Check number of faces to sort
		cmp/gt	r11,r0
		bf	.z_fewfaces
		mov	r0,r11
; if faces > 2
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
		bf	.z_high			; bf=back to front, bt=front to back
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
; only 1 or 2 faces
; TODO: this is too much for 2 faces...

.z_fewfaces:
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

; ====================================================================
; --------------------------------------------------------
; Task list for MD-to-MARS tasks, call these directly
; in the Genesis side
; 
; *** 68k EXAMPLES ***
; 
; Single task:
; 	move.l	#CmdTaskMd_SetBitmap,d0	; 32X display OFF
; 	moveq	#0,d1
; 	bsr	System_MdMars_Call
; 	
; Queued task:
; 	move.l	#CmdTaskMd_LoadSPal,d0	; Load palette
; 	move.l	#Palette_Data,d1	; Color data
; 	moveq	#0,d2			; Start from
; 	move.w	#255,d3			; Number of colors
; 	moveq	#0,d4			; OR value
; 	move.w	#$7FFF,d5		; AND value for BG
; 	bsr	System_MdMars_AddTask	; Insert task
; 	; Then more tasks go here...
; .wait:
;	bsr	System_MdMars_CheckBusy	; Check if active
; 	bne.s	.wait			; bne - busy
; 	bsr	System_MdMars_SendAll	; Send all tasks
; --------------------------------------------------------

		align 4

; ------------------------------------------------
; CALLS EXCLUSIVE TO MASTER CPU
; ------------------------------------------------

; ------------------------------------------------
; Set SuperVDP bitmap value
;
; @($04,r14) - SuperVDP bitmap number (0-3)
; ------------------------------------------------

CmdTaskMd_SetBitmap:
		mov 	#_vdpreg,r1
.wait_fb:	mov.w   @($A,r1),r0
		tst     #2,r0
		bf      .wait_fb
		mov	@($04,r14),r0
		mov.b	r0,@(bitmapmd,r1)
		rts
		nop
		align 4

; ------------------------------------------------
; Load palette to SuperVDP from MD
;
; @($04,r14) - Palette data
; @($08,r14) - Start from
; @($0C,r14) - Number of colors
; @($10,r14) - OR value
; ------------------------------------------------

CmdTaskMd_LoadSPal:
		mov	r14,r13
		add	#4,r13
		mov	@r13+,r1
		mov	@r13+,r2
		mov	@r13+,r3
		mov	@r13+,r4
		mov	#MarsVideo_LoadPal,r0
		jmp	@r0
		nop
		align 4

; ------------------------------------------------
; CALLS EXCLUSIVE TO SLAVE CPU
; ------------------------------------------------

; ------------------------------------------------
; Make new object and insert it to specific slot
;
; @($04,r14) - Object slot
; @($08,r14) - Object data
; @($0C,r14) - Object options:
;	       %????????????????????????pppppppp
;		p - index pixel increment value
; ------------------------------------------------

CmdTaskMd_ObjectSet:
		mov	#RAM_Mars_Objects+(sizeof_mdlobj*9),r12
		mov	r14,r13
		add	#4,r13
		mov	@r13+,r0
		mov	#sizeof_mdlobj,r1
		mulu	r1,r0
		sts	macl,r0
		add	r0,r12
		xor	r0,r0
		mov	@r13+,r1
		mov	r1,@(mdl_data,r12)
		mov	@r13+,r1
		mov	r1,@(mdl_option,r12)
		mov	r0,@(mdl_x_pos,r12)
		mov	r0,@(mdl_y_pos,r12)
		mov	r0,@(mdl_z_pos,r12)
		mov	r0,@(mdl_x_rot,r12)
		mov	r0,@(mdl_y_rot,r12)
		mov	r0,@(mdl_z_rot,r12)
		rts
		nop
		align 4
		
; ------------------------------------------------
; Move/Rotate object from slot
; 
; @($04,r14) - Object slot
; @($08,r14) - Object X pos
; @($0C,r14) - Object Y pos
; @($10,r14) - Object Z pos
; @($14,r14) - Object X rot
; @($18,r14) - Object Y rot
; @($1C,r14) - Object Z rot
; ------------------------------------------------

CmdTaskMd_ObjectPos:
		mov	#RAM_Mars_Objects+(sizeof_mdlobj*9),r12
		mov	r14,r13
		add	#4,r13
		mov	@r13+,r0
		mov	#sizeof_mdlobj,r1
		mulu	r1,r0
		sts	macl,r0
		add	r0,r12
		mov	@r13+,r1
		mov	@r13+,r2
		mov	@r13+,r3
		mov	@r13+,r4
		mov	@r13+,r5
		mov	@r13+,r6
		mov	r1,@(mdl_x_pos,r12)
		mov	r2,@(mdl_y_pos,r12)
		mov	r3,@(mdl_z_pos,r12)
		mov	r4,@(mdl_x_rot,r12)
		mov	r5,@(mdl_y_rot,r12)
		mov	r6,@(mdl_z_rot,r12)
		rts
		nop
		align 4

; ------------------------------------------------
; Clear ALL objects, including layout
; ------------------------------------------------

CmdTaskMd_ObjectClrAll:
		sts	pr,@-r15
		mov	#MarsMdl_Init,r0
		jsr	@r0
		mov	r14,@-r15
		mov	@r15+,r14
		lds	@r15+,pr
		rts
		nop
		align 4

; ------------------------------------------------
; Set new map data
; 
; @($04,r14) - layout data
; ------------------------------------------------

CmdTaskMd_MapSet:
		sts	pr,@-r15
		mov	@(4,r14),r1
		mov	#MarsLay_Make,r0
		jsr	@r0
		mov	r14,@-r15
		mov	@r15+,r14
		lds	@r15+,pr
		rts
		nop
		align 4
		
; ------------------------------------------------
; Set camera position
; 
; @($04,r14) - Camera slot (TODO)
; @($08,r14) - Camera X pos
; @($0C,r14) - Camera Y pos
; @($10,r14) - Camera Z pos
; @($14,r14) - Camera X rot
; @($18,r14) - Camera Y rot
; @($1C,r14) - Camera Z rot
; ------------------------------------------------

CmdTaskMd_CameraPos:
		mov	#RAM_Mars_ObjCamera,r12
		mov	r14,r13
		add	#8,r13
		mov	@r13+,r1
		mov	@r13+,r2
		mov	@r13+,r3
		mov	@r13+,r4
		mov	@r13+,r5
		mov	@r13+,r6
		mov	r1,@(cam_x_pos,r12)
		mov	r2,@(cam_y_pos,r12)
		mov	r3,@(cam_z_pos,r12)
		mov	r4,@(cam_x_rot,r12)
		mov	r5,@(cam_y_rot,r12)
		mov	r6,@(cam_z_rot,r12)
		rts
		nop
		align 4

; ------------------------------------------------
; Set PWM to play
; 
; @($04,r14) - Channel slot
; @($08,r14) - Start point
; @($0C,r14) - End point
; @($10,r14) - Loop point
; @($14,r14) - Pitch
; @($18,r14) - Volume
; @($1C,r14) - Settings:
; 		%00000000 00000000LR
;		LR - output bits
; ------------------------------------------------

CmdTaskMd_PWM_SetChnl:
		sts	pr,@-r15
		mov	@($04,r14),r1
		mov	@($08,r14),r2
		mov	@($0C,r14),r3
		mov	@($10,r14),r4
		mov	@($14,r14),r5
		mov	@($18,r14),r6
		mov	@($1C,r14),r7
		bsr	MarsSound_SetPwm
		nop
		lds	@r15+,pr
		rts
		nop
		align 4

; ------------------------------------------------
; Set PWM pitch to multiple channels
; 
; @($04,r14) - Channel 0 pitch
; @($08,r14) - Channel 1 pitch
; @($0C,r14) - Channel 2 pitch
; @($10,r14) - Channel 3 pitch
; @($14,r14) - Channel 4 pitch
; @($18,r14) - Channel 5 pitch
; @($1C,r14) - Channel 6 pitch
; ------------------------------------------------

CmdTaskMd_PWM_MultPitch:
		sts	pr,@-r15
		mov	#$FFFF,r7
		mov	r14,r13
		add	#4,r13
		mov	#0,r1
	rept MAX_PWMCHNL		; MAX: 7
		mov	@r13+,r2
		and	r7,r2
		bsr	MarsSound_SetPwmPitch
		nop
		add	#1,r1
	endm
		lds	@r15+,pr
		rts
		nop
		align 4
		
; 		mov	#0,r1
; 		mov	#WAV_LEFT,r2
; 		mov	#WAV_LEFT_E,r3
; 		mov	#WAV_LEFT,r4
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

; ----------------------------------------

		ltorg

; =================================================================
; ------------------------------------------------
; Slave | Watchdog interrupt
; ------------------------------------------------

s_irq_custom:
		mov	r2,@-r15
		mov	#_FRT,r1
		mov.b   @(7,r1),r0
		xor     #2,r0
		mov.b   r0,@(7,r1)

; 		mov.w	@(marsGbl_ZSortReq,gbr),r0
; 		cmp/eq	#1,r0
; 		bf	.no_req
; 		xor	r0,r0
; 		mov.w	r0,@(marsGbl_ZSortReq,gbr)
; 
; ; 	; Sorting task start here
; ; 		mov.w	@(marsGbl_MdlFacesCntr,gbr),r0
; ; 		cmp/eq	#0,r0
; ; 		bt	.no_request
; ; 		mov	r3,@-r15
; ; 		mov	r4,@-r15
; ; 		mov	r5,@-r15
; ; 		mov	r6,@-r15
; ; 		mov	#CS3+$44,r1
; ; 		mov	@r1,r0
; ; 		add 	#1,r0
; ; 		mov	r0,@r1
; ; 		mov	@r15+,r6
; ; 		mov	@r15+,r5
; ; 		mov	@r15+,r4
; ; 		mov	@r15+,r3
; ; .no_request:
; ; 	; End
; ; 
; 
; .no_req:
		mov	#$FFFFFE80,r1
		mov.w   #$A518,r0		; Watchdog OFF
		mov.w   r0,@r1
		or      #$20,r0
		mov.w   r0,@r1
		mov	#1,r2
		mov.w   #$5A7F,r0		; Timer for next one
		or	r2,r0
		mov.w	r0,@r1
		mov	@r15+,r2
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

; ====================================================================
; ----------------------------------------------------------------
; MARS DATA
; ----------------------------------------------------------------

		align 4
sin_table	binclude "system/mars/data/sinedata.bin"
		align 4
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
	if MOMPASS=6
		message "MARS RAM from \{((SH2_RAM)&$FFFFFF)} to \{((.here)&$FFFFFF)}"
	endif
		finish
		
; ====================================================================
; ----------------------------------------------------------------
; MARS Sound RAM
; ----------------------------------------------------------------

			struct MarsRam_Sound
MarsSnd_PwmChnls	ds.b sizeof_sndchn*MAX_PWMCHNL
sizeof_marssnd		ds.l 0
			finish

; ====================================================================
; ----------------------------------------------------------------
; MARS Video RAM
; ----------------------------------------------------------------

			struct MarsRam_Video
RAM_Mars_ObjCamera	ds.b sizeof_camera		; Camera buffer
RAM_Mars_ObjLayout	ds.b sizeof_layout		; Layout buffer
RAM_Mars_Objects	ds.b sizeof_mdlobj*MAX_MODELS	; Objects list
RAM_Mars_Polygons_0	ds.b sizeof_polygn*MAX_FACES	; Polygon list 0
RAM_Mars_Polygons_1	ds.b sizeof_polygn*MAX_FACES	; Polygon list 1
RAM_Mars_VdpDrwList	ds.b sizeof_plypz*MAX_SVDP_PZ	; Pieces list
RAM_Mars_FbDrwnBuff	ds.b (SCREEN_WIDTH/8)*SCREEN_HEIGHT
RAM_Mars_VdpDrwList_e	ds.l 0				; (end-of-list label)
RAM_Mars_PlgnList_0	ds.l MAX_FACES			; Pointer list(s)
RAM_Mars_PlgnList_1	ds.l MAX_FACES
RAM_Mars_Plgn_ZList	ds.l MAX_FACES*2		; Z value / foward faces
RAM_Mars_MdTasksFifo_M	ds.l MAX_MDTSKARG*MAX_MDTASKS	; Request list for Master: SVDP and PWM interaction exclusive
RAM_Mars_MdTasksFifo_S	ds.l MAX_MDTSKARG*MAX_MDTASKS	; Request list for Slave: Controlling objects and camera
RAM_Mars_Palette	ds.w 256			; Indexed palette
RAM_Mars_PlgnNum_0	ds.w 1				; Number of polygons to read, both buffers
RAM_Mars_PlgnNum_1	ds.w 1				;
sizeof_marsvid		ds.l 0
			finish
			
; ====================================================================
; ----------------------------------------------------------------
; MARS System RAM
; ----------------------------------------------------------------

			struct MarsRam_System
RAM_Mars_Global		ds.w sizeof_MarsGbl		; keep it as a word
sizeof_marssys		ds.l 0
			finish
