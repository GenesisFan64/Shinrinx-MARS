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
		mov	#MarsSound_PWM,r0
		jsr	@r0
		nop
		lds	@r15+,pr
.exit:
		mov	#_FRT,r1
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

; ----------------------------------
; Update Indexed-palette
; ----------------------------------
		mov 	#_vdpreg,r1
.min_r		mov.w	@(10,r1),r0			; Wait for FEN to clear
		and	#%10,r0
		cmp/eq	#2,r0
		bt	.min_r
		mov.l	r2,@-r15
		mov.l	r3,@-r15
		mov.l	r4,@-r15
		mov.l	r5,@-r15
		mov.l	r6,@-r15
		mov.l	#_vdpreg,r1			; Wait for palette access ok
.wait		mov.b	@(vdpsts,r1),r0
		tst	#$20,r0
		bt	.wait
		mov.l	#RAM_Mars_Palette,r1		; Send palette stored on RAM
		mov.l	#_palette,r2
 		mov.l	#256,r3
		mov.l	#%0101011011110001,r4		; transfer size 2 / burst
		mov.l	#_DMASOURCE0,r5 		; _DMASOURCE = $ffffff80
		mov.l	#_DMAOPERATION,r6 		; _DMAOPERATION = $ffffffb0
		mov.l	r1,@r5				; set source address
		mov.l	r2,@(4,r5)			; set destination address
		mov.l	r3,@(8,r5)			; set length
		xor	r0,r0
		mov.l	r0,@r6				; Stop OPERATION
		xor	r0,r0
		mov.l	r0,@($C,r5)			; clear TE bit
		mov.l	r4,@($C,r5)			; load mode
		add	#1,r0
		mov.l	r0,@r6				; Start OPERATION
		mov.l	@r15+,r6
		mov.l	@r15+,r5
		mov.l	@r15+,r4
		mov.l	@r15+,r3
		mov.l	@r15+,r2
		mov 	#0,r0				; Clear VintFlag for Master
		mov.w	r0,@(marsGbl_VIntFlag_M,gbr)
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
		mov	r4,@-r15
		mov	r5,@-r15

		mov	#_sysreg+comm8,r1
		mov	#RAM_Mars_MdTasksFifo_1,r2	
		mov.w	@(marsGbl_MdTaskList_Sw,gbr),r0
		tst     #1,r0
		bf	.trnsf
		mov	#RAM_Mars_MdTasksFifo_2,r2
.trnsf:
		mov.w	@(4,r1),r0
		cmp/eq	#-1,r0
		bt	.exit
		cmp/eq	#0,r0
		bt	.trnsf
		mov	@r1,r0
		mov	r0,@r2
		add	#4,r2
		xor	r0,r0
		mov.w	r0,@(4,r1)
		nop
		nop
		bra	.trnsf
		nop
.exit:

		mov 	@r15+,r5
		mov 	@r15+,r4		
		mov 	@r15+,r3
		mov 	@r15+,r2
		rts
		nop
		align 4

; 		mov.b	@(4,r1),r0
; 		cmp/eq	#0,r0
; 		bt	.trnsfr_done
; 		mov.b	@(5,r1),r0	; Get tag
; 		cmp/eq	#2,r0		; Got 2? (finish)
; 		bt	.trnsfr_done
; 		cmp/eq	#1,r0		; Got 1? (copy data)
; 		bf	.next_long
; .retry:
; 		mov.w	@r1,r0		; comm8 - xxxx0000
; 		extu	r0,r0
; 		shll16	r0
; 		mov	r0,r3
; 		mov.w	@(2,r1),r0	; comm10 - 0000xxxx
; 		extu	r0,r0
; 		or	r3,r0
; 		mov	r0,@r2
; 		mov	@r2,r3
; 		cmp/eq	r0,r3
; 		bf	.retry
; 		mov	#0,r0
; 		mov.b	r0,@(5,r1)
; 		nop
; 		nop
; 		bra	.next_long
; 		add	#4,r2
; .trnsfr_done:
; 		mov	#0,r0
; 		mov.w	r0,@(4,r1)		; Finish transfer + clear tag
; 		nop
; 		nop
; 		mov	#_sysreg+comm15,r1
; 		mov	#1,r0
; 		mov.b	r0,@r1
		
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
		mov	#%00001000,r0			; Two-way mode
		mov.w	r0,@r1
		mov	#%00011001,r0			; Cache purge / Two-way mode / Cache ON
		mov.w	r0,@r1
		mov.l	#$20,r0				; Interrupts ON
		ldc	r0,sr

; --------------------------------------------------------
; Loop
; --------------------------------------------------------

master_loop:
		mov	#0,r0
		mov	#_sysreg+comm14,r1
		mov.b	r0,@r1
.mstr_wait:
		mov.b	@r1,r0			; Any request from Slave?
		cmp/eq	#0,r0
		bf	.mstr_free		; If !=0, start drawing
		nop
		bra	.mstr_wait
		nop

; --------------------------------------------------------
; Start building and drawing polygons
; --------------------------------------------------------

.mstr_free:
		mov.l	#$FFFFFE92,r0
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
		stc	sr,r1
		mov	#$F0,r0
		ldc	r0,sr
		mov.w	@(marsGbl_MdTaskList_Sw,gbr),r0		; Swap tasks buffer
 		xor	#1,r0
 		mov.w	r0,@(marsGbl_MdTaskList_Sw,gbr)
 		ldc	r1,sr
		mov	#MAX_MDTASKS,r13
		mov	#RAM_Mars_MdTasksFifo_1,r14
		mov.w	@(marsGbl_MdTaskList_Sw,gbr),r0
		tst     #1,r0
		bf	.next_req
		mov	#RAM_Mars_MdTasksFifo_2,r14
.next_req:
		mov	@r14,r0
		cmp/eq	#0,r0
		bt	.no_task
		mov	r13,@-r15
		jsr	@r0
		nop
		mov	@r15+,r13
		mov	#0,r0
		mov	r0,@r14

		mov	#_sysreg+comm15,r1
		mov	#0,r0
		mov.b	r0,@r1
		mov	#_sysreg+comm2,r1
		mov.w	@r1,r0
		add	#1,r0
		mov.w	r0,@r1
.no_task:
		mov	#MAX_MDTSKARG*4,r0
		dt	r13
		bf/s	.next_req
		add	r0,r14
.no_req:
		mov	#_sysreg+comm0,r4
		mov.w	@r4,r0
		add	#1,r0
		mov.w	r0,@r4
		
; --------------------------------------------------------
; Start building polygons from models
; 
; CAMERA ANIMATION IS DONE ON THE
; GENESIS SIDE
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
	; Start Zsorting faces
		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
		tst     #1,r0
		bf	.page_2
		mov 	#RAM_Mars_PlgnList_0,r14
		mov 	#RAM_Mars_PlgnNum_0,r13
		bsr	slv_sort_z
		nop
		bra	.swap_now
		nop
.page_2:
		mov 	#RAM_Mars_PlgnList_1,r14
		mov 	#RAM_Mars_PlgnNum_1,r13
		bsr	slv_sort_z
		nop
.swap_now:
; 		mov.w	@r13,r0				; DEBUG: report number of faces
; 		mov	#_sysreg+comm0,r1
; 		mov.w	r0,@r1
		
	; Check if MASTER finished
		mov.l	#_sysreg+comm14,r1		; Master CPU still drawing pieces?
.wait_master:
		mov.b	@r1,r0
		cmp/eq	#1,r0
		bt	.still_drwing
		mov.w	@(marsGbl_PolyBuffNum,gbr),r0	; Swap polygon buffer
 		xor	#1,r0
 		mov.w	r0,@(marsGbl_PolyBuffNum,gbr)
		mov	#1,r2				; Start drawing on Master
		mov.l	#_sysreg+comm14,r1
		mov.b	r2,@r1
.still_drwing:
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

; 		align 4
; slv_task_list:
; 		dc.l slv_nulltask	; NULL entry
; 		dc.l slv_task_01	; $01 - Load SuperVDP palette
; 		dc.l slv_nulltask	; $02 - 
; 		dc.l slv_nulltask	; $03 -
; 		dc.l slv_task_04	; $04 - Load SuperVDP palette directly
; 		dc.l slv_nulltask	; $05 - Load SuperVDP palette for fading
; 		dc.l slv_nulltask	; $06 - SuperVDP Fade in
; 		dc.l slv_nulltask	; $07 - SuperVDP Fade out
; 
; 		dc.l slv_task_08	; $08 - Load object to slot
; 		dc.l slv_nulltask	; $09 - Autoload object (if Layout is active)
; 		dc.l slv_task_0A	; $0A - Set object position and rotation
; 		dc.l slv_nulltask	; $0B - Set object animation
; 		dc.l slv_task_0C	; $0C - Set layout data
; 		dc.l slv_task_0D	; $0D - Set camera poisition and rotation
; 		dc.l slv_nulltask	; $0E - 
; 		dc.l slv_task_0F	; $0F - Delete ALL objects (including Layout)
; 
; 		dc.l slv_nulltask	; $10 - 
; 		dc.l slv_nulltask	; $11 - 
; 		dc.l slv_nulltask	; $12 -
; 		dc.l slv_nulltask	; $13 -
; 		dc.l slv_nulltask	; $14 -
; 		dc.l slv_nulltask	; $15 -
; 		dc.l slv_nulltask	; $16 -
; 		dc.l slv_nulltask	; $17 -
		
; ; ------------------------------------------------
; ; Task $00
; ; ------------------------------------------------
; 
; slv_nulltask:
; 		rts
; 		nop
; 		align 4

; ------------------------------------------------
; Set SuperVDP bitmap value
;
; @($04,r14) - SuperVDP bitmap number (0-3)
; ------------------------------------------------

CmdTaskMd_SetBitmap:
		mov 	#_vdpreg,r1
		mov	@($04,r14),r0
		mov.b	r0,@(bitmapmd,r1)
		rts
		nop
		align 4

; ------------------------------------------------
; Load palette to SuperVDP
;
; @($04,r14) - Palette data
; @($08,r14) - Start from
; @($0C,r14) - Number of colors
; @($10,r14) - OR value
; @($14,r14) - AND background value
; ------------------------------------------------

CmdTaskMd_LoadSPal:
		sts	pr,@-r15
		mov	r14,r13
		add	#4,r13
		mov	@r13+,r1
		mov	@r13+,r2
		mov	@r13+,r3
		mov	@r13+,r4
		mov	#MarsVideo_LoadPal,r0
		jsr	@r0
		nop
; 		mov	@r13+,r1
; 		mov	#RAM_Mars_Palette,r2
; 		mov.w	@r2,r0
; 		and	r1,r0
; 		mov.w	r0,@r2
		lds	@r15+,pr
		rts
		nop
		align 4
		
; ------------------------------------------------
; Make new object and insert it to specific slot
;
; @($04,r14) - Object slot
; @($08,r14) - Object data
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
; @($1C,r14) - Stereo output bits (%LR)
; ------------------------------------------------

CmdTaskMd_SetPWM:
		sts	pr,@-r15
		
		mov	@($04,r14),r1
		mov	@($08,r14),r2
		mov	@($0C,r14),r3
		mov	@($10,r14),r4
		mov	@($14,r14),r5
		mov	@($18,r14),r6
		mov	@($1C,r14),r7
		bsr	MarsSound_SetChannel
		nop

; 		mov	@($04,r14),r1
; 		mov	@($08,r14),r2
; 		mov	@($0C,r14),r3
; 		mov	@($10,r14),r4
; 		mov	@($14,r14),r5
; 		mov	@($18,r14),r6
; 		mov	@($1C,r14),r7
; 		mov	#MarsSound_SetChannel,r0
; 		jsr	@r0
; 		nop
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
; Slave | Custom interrupt
; 
; Autosort faces on the background
; ------------------------------------------------

s_irq_custom:
		mov	r2,@-r15
		mov	#_FRT,r1
		mov.b   @(7,r1),r0
		xor     #2,r0
		mov.b   r0,@(7,r1)
; 
; 	; Sorting task start here
; 		mov.w	@(marsGbl_MdlFacesCntr,gbr),r0
; 		cmp/eq	#0,r0
; 		bt	.no_request
; 		mov	r3,@-r15
; 		mov	r4,@-r15
; 		mov	r5,@-r15
; 		mov	r6,@-r15
; 		mov	#CS3+$44,r1
; 		mov	@r1,r0
; 		add 	#1,r0
; 		mov	r0,@r1
; 		mov	@r15+,r6
; 		mov	@r15+,r5
; 		mov	@r15+,r4
; 		mov	@r15+,r3
; .no_request:
; 	; End
; 
		mov	#$FFFFFE80,r1
		mov.w   #$A518,r0
		mov.w   r0,@r1
		or      #$20,r0
		mov.w   r0,@r1
		mov	#1,r2
		mov.w   #$5A00,r0
		or	r2,r0
		mov.w	r0,@r1
		mov	@r15+,r2
		rts
		nop
		align 4
		ltorg

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
MARSSnd_Pwm		ds.b sizeof_sndchn*MAX_PWMCHNL
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
RAM_Mars_MdTasksFifo_1	ds.l MAX_MDTSKARG*MAX_MDTASKS	; Request list from MD for Normal tasks
RAM_Mars_MdTasksFifo_2	ds.l MAX_MDTSKARG*MAX_MDTASKS	; Two lists: Read/Write
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
