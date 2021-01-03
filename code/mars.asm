; ====================================================================		
; ----------------------------------------------------------------
; MARS SH2 Section, CODE for both CPUs
; RAM and some DATA goes here
; ----------------------------------------------------------------

		phase CS3			; now we are at SDRAM
		cpu SH7600			; should be SH7095 but ASL doesn't have it, this is close enough

; =================================================================

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
marsGbl_MdlFacesCntr	ds.w 1		; And the number of faces stored on that list
marsGbl_PolyBuffNum	ds.w 1		; Buffer switcher: READ/WRITE or WRITE/READ
marsGbl_PzListCntr	ds.w 1		; Number of graphic pieces to draw
marsGbl_DrwTask		ds.w 1		; Drawing task for Watchdog
marsGbl_VIntFlag_M	ds.w 1		; Reset if VBlank finished on Master CPU
marsGbl_VIntFlag_S	ds.w 1		; The same but for Slave CPU
marsGbl_DivReq_M	ds.w 1		; Tell Watchdog we are in the middle of division (skips task)
marsGbl_MdlDrawReq	ds.w 1		; Flag to draw models at the request from MD
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
; Master | CMD Interrupt (MD request)
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
; Update Indexed-palette
; (Only on VBlank)
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
		mov.l	#_FRT,r1
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
; Master | Custom interrupt
; ------------------------------------------------

; m_irq_custom:
; moved to video.asm

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
		mov 	#0,r0				; Clear VintFlag for Slave
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
		mov.l	#CS3|$40000,r15		; Set default Stack for Master
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
		mov.l   #$FFFFFEE2,r0		; Pre-init special interrupt
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
; 
; The polygons use 2 buffers:
; The main loop builds the polygons for the next frame
; (to the WRITE buffer)
; And the special interrupt is used to draw polygons to the
; framebuffer in this frame
; (from the READ buffer)
; ----------------------------------------------------------------

SH2_M_HotStart:
		mov.l	#CS3|$40000,r15			; Stack again if coming from RESET
		mov.l	#RAM_Mars_Global,r14		; GBR - Global values/variables
		ldc	r14,gbr
	
		mov.l	#$F0,r0				; Interrupts OFF
		ldc	r0,sr
		mov.l	#_CCR,r1			; Set this cache mode
		mov	#0,r0
		mov.w	r0,@r1
		mov	#$19,r0
		mov.w	r0,@r1
		mov	#_sysreg,r1
		mov	#VIRQ_ON|CMDIRQ_ON,r0		; Enable these interrupts		
    		mov.b	r0,@(intmask,r1)

		mov 	#CACHE_START,r1			; Load 3D Routines on CACHE	
		mov 	#$C0000000,r2
		mov 	#(CACHE_END-CACHE_START)/4,r3
.copy:
		mov 	@r1+,r0
		mov 	r0,@r2
		add 	#4,r2
		dt	r3
		bf	.copy
		bsr	MarsVideo_Init			; Init video
		nop
		bsr	MarsSound_Init			; Init sound
		nop
		
; ------------------------------------------------

		mov	#Palette_Puyo,r1
		mov	#256,r3
		bsr	MarsVideo_LoadPal
		mov	#0,r2
		mov	#($1F<<10)|($E<<5),r0
		mov	#RAM_Mars_Palette,r1
		mov.w	r0,@r1
		
		mov	#0,r1
		mov	#WAV_LEFT,r2
		mov	#WAV_LEFT_E,r3
		mov	r2,r4
		mov	#$100,r5
		mov	#0,r6
		bsr	MarsSound_SetChannel
		mov	#%10,r7
		mov	#1,r1
		mov	#WAV_RIGHT,r2
		mov	#WAV_RIGHT_E,r3
		mov	r2,r4
		mov	#$100,r5
		mov	#0,r6
		bsr	MarsSound_SetChannel
		mov	#%01,r7
		
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
		mov.b	@r1,r0			; Any DRAW request?
		cmp/eq	#0,r0
		bf	.mstr_free		; If !=0, start drawing
; 		mov	#$16,r0			; Small delay and retry
; .mstr_delay:
; 		nop
; 		dt	r0
; 		bf/s	.mstr_delay
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
		bsr	MarsRndr_SetWatchdog
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

	; r14 - Polygon pointers to read
	; r13 - NumOf Polygons to use
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

.wait_pz: 	mov.w	@(marsGbl_PzListCntr,gbr),r0	; Any polygons remaining on interrupt?
		cmp/eq	#0,r0
		bf	.wait_pz
.wait_task:	mov.w	@(marsGbl_DrwTask,gbr),r0	; Any draw task active?
		cmp/eq	#0,r0
		bf	.wait_task
		mov.l   #$FFFFFE80,r1			; Stop watchdog
		mov.w   #$A518,r0
		mov.w   r0,@r1
		bsr	MarsVideo_FrameSwap		; Swap frame (waits VBlank)
		nop

	; --------------------
	; DEBUG counter
		mov	#_sysreg+comm4,r1
		mov.w	@r1,r0
		add	#1,r0
		mov.w	r0,@r1
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
		mov.l	#_CCR,r1			; Set this cache mode
		mov	#0,r0
		mov.w	r0,@r1
		mov	#$19,r0
		mov.w	r0,@r1
		mov	#_sysreg,r1
		mov.l	#VIRQ_ON||PWMIRQ_ON|CMDIRQ_ON,r0	; IRQ enable bits
    		mov.b	r0,@(intmask,r1)			; clear IRQ ACK regs


; ------------------------------------------------
; REMINDER: In blender, each block is
; 1 meter: $20000 pixels

		bsr	MarsMdl_Init
		nop
		mov	#$20,r0			; Interrupts ON
		ldc	r0,sr
		mov	#RAM_Mars_Objects,r1
		mov	#TEST_MODEL,r0
		mov	r0,@r1

; --------------------------------------------------------
; Loop
; --------------------------------------------------------

slave_loop:
		mov	#_sysreg+comm15,r14		; Any request from MD?
		mov.b	@r14,r0
		cmp/eq	#0,r0
		bt	.no_requests

; --------------------------------------------

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
		mov.w	@(marsGbl_MdlDrawReq,gbr),r0
		cmp/eq	#1,r0
		bt	slave_loop
 		mov	#1,r0
 		mov.w	r0,@(marsGbl_MdlDrawReq,gbr)
.no_requests:
 		mov.w	@(marsGbl_MdlDrawReq,gbr),r0
 		cmp/eq	#0,r0
 		bt	slave_loop

; --------------------------------------------------------
; Start building polygons from models
; --------------------------------------------------------
; MOVED TO MD
; 	Camera animation
; 		mov.l	#_sysreg+comm14,r1		; Master CPU still drawing pieces?
; 		mov.b	@r1,r0
; 		cmp/eq	#1,r0
; 		bt	slave_loop
; 		mov	#RAM_Mars_ObjCamera,r14
; 		mov	@(cam_animdata,r14),r13
; 		cmp/pl	r13
; 		bf	.no_camanim
; 		mov	@(cam_animtimer,r14),r0
; 		dt	r0
; 		bt	.wait_camanim
; 		mov	#500,r2				; TEMPORAL: max frames
; 		mov	@(cam_animframe,r14),r0
; 		mov	r0,r1
; 		add	#1,r0
; 		cmp/eq	r2,r0
; 		bf	.on_frames
; 		xor	r0,r0
; .on_frames:
; 		mov	r0,@(cam_animframe,r14)
; 		mov	#$18,r0
; 		mulu	r0,r1
; 		sts	macl,r0 	
; 		add	r0,r13
; 		mov	@r13+,r1
; 		mov	@r13+,r2
; 		mov	@r13+,r3
; 		mov	@r13+,r4
; 		mov	@r13+,r5
; 		mov	@r13+,r6
; 		mov	r1,@(cam_x_pos,r14)
; 		mov	r2,@(cam_y_pos,r14)
; 		mov	r3,@(cam_z_pos,r14)
; 		mov	r4,@(cam_x_rot,r14)
; 		mov	r5,@(cam_y_rot,r14)
; 		mov	r6,@(cam_z_rot,r14)
; 		mov	#8,r0
; .wait_camanim:
; 		mov	r0,@(cam_animtimer,r14)	
; .no_camanim:

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
		mov	#MAX_MODELS,r13
.loop:
		mov	@(mdl_data,r14),r0
		cmp/eq	#0,r0
		bt	.invlid
		
; 	; WIP offbounds check for current object
; 		mov	#RAM_Mars_ObjCamera,r0
; 		mov	@(mdl_x_pos,r14),r1
; 		mov	@(mdl_y_pos,r14),r2
; 		mov	@(mdl_z_pos,r14),r3
; 		mov	@(cam_x_pos,r0),r4
; 		mov	@(cam_y_pos,r0),r5
; 		mov	@(cam_z_pos,r0),r6
; 		add	r4,r1
; 		add	r5,r2	
; 		add	r6,r3
; 		mov	#-$20000*3,r4
; 		mov	#-$20000*2,r5
; ; 		mov	#-$20000*4,r6
; 		neg	r4,r0
; 		cmp/gt	r4,r1			; X limits
; 		bf	.invlid
; 		cmp/ge	r0,r1
; 		bt	.invlid
; 		neg	r5,r0	
; 		cmp/gt	r5,r2			; Y limits
; 		bf	.invlid
; 		cmp/ge	r0,r2
; 		bt	.invlid
; 		neg	r6,r0	
; 		cmp/gt	r6,r3			; Z limits
; 		bf	.invlid
; 		cmp/ge	r0,r3
; 		bt	.invlid
		
		mov	r13,@-r15
		mov	@(mdl_anim,r14),r13
		cmp/pl	r13
		bf	.no_anim
		bsr	MarsMdl_Animate
		nop
.no_anim:
		bsr	MarsMdl_MakeModel
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
		mov.w	@r13,r0				; DEBUG: report number of faces
		mov	#_sysreg+comm0,r1
		mov.w	r0,@r1
		
	; Wait states
		mov.l	#_sysreg+comm14,r1		; Master CPU still drawing pieces?
.wait_master:
		mov.b	@r1,r0
		cmp/eq	#1,r0
		bt	.hold_on
		mov.w	@(marsGbl_PolyBuffNum,gbr),r0
 		xor	#1,r0
 		mov.w	r0,@(marsGbl_PolyBuffNum,gbr)
 		mov	#0,r0
 		mov.w	r0,@(marsGbl_MdlDrawReq,gbr)
		bsr	Slv_SetMasterTask
		mov	#1,r2
.hold_on:
		bra	slave_loop
		nop
		align 4
		ltorg

; ----------------------------------------
; Bubble sorting
	
slv_sort_z:
		sts	pr,@-r15
		mov	#0,r0					; Reset current PlgnNum
		mov.w	r0,@r13
		mov	#RAM_Mars_Plgn_ZList,r12	
		mov.w	@(marsGbl_MdlFacesCntr,gbr),r0		; Check number of faces to sort
		cmp/eq	#0,r0
		bt	.z_end
		mov	#2,r11
		cmp/gt	r11,r0
		bt	.z_normal
		mov	r0,r11
		bra	.z_fewfaces
		nop
		
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

; ----------------------------------------

Slv_SetMasterTask:
		mov.l	#_sysreg+comm14,r1
		mov.b	r2,@r1
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
RAM_Mars_Palette	ds.w 256
RAM_Mars_PlgnList_0	ds.l MAX_FACES			; Pointer list(s)
RAM_Mars_PlgnList_1	ds.l MAX_FACES
RAM_Mars_Plgn_ZList	ds.l MAX_FACES*2		; Z value / foward faces | backward faces
RAM_Mars_PlgnNum_0	ds.w 1
RAM_Mars_PlgnNum_1	ds.w 1
RAM_Mars_ObjCamera	ds.b sizeof_camera*4
RAM_Mars_Objects	ds.b sizeof_mdlobj*MAX_MODELS
RAM_Mars_Polygons_0	ds.b sizeof_polygn*MAX_FACES	; Polygon list 0
RAM_Mars_Polygons_1	ds.b sizeof_polygn*MAX_FACES	; Polygon list 1
RAM_Mars_VdpDrwList	ds.b sizeof_plypz*MAX_SVDP_PZ
RAM_Mars_VdpDrwList_e	ds.l 0
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
