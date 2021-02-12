; ====================================================================
; ----------------------------------------------------------------
; MD Sound
; ----------------------------------------------------------------

; ====================================================================
; ----------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; Init Sound
; 
; Uses:
; a0-a1,d0-d1
; --------------------------------------------------------

Sound_Init:
		move.w	#$0100,(z80_bus).l		; Stop Z80
		move.b	#1,(z80_reset).l		; Reset
.wait:
		btst	#0,(z80_bus).l			; Wait for it
		bne.s	.wait
		lea	(z80_cpu).l,a0
		move.w	#$1FFF,d0
		moveq	#0,d1
.cleanup:
		move.b	d1,(a0)+
		dbf	d0,.cleanup
		lea	(Z80_CODE).l,a0			; Send sound code
		lea	(z80_cpu).l,a1
		move.w	#(Z80_CODE_END-Z80_CODE)-1,d0
.copy:
		move.b	(a0)+,(a1)+
		dbf	d0,.copy
		move.b	#1,(z80_reset).l		; Reset
		nop 
		nop 
		nop 
		move.w	#0,(z80_bus).l
		rts

; --------------------------------------------------------
; Sound_DMA_Pause
; 
; Call this before doing any DMA task
; --------------------------------------------------------

Sound_DMA_Pause:
		move.w	sr,-(sp)
		or.w	#$700,sr
.retry:
		move.w	#$0100,(z80_bus).l		; Stop Z80
.wait:
		btst	#0,(z80_bus).l			; Wait for it
		bne.s	.wait
		move.b	#1,(z80_cpu+commZRomBlk)	; Tell Z80 we want the bus
		move.b	(z80_cpu+commZRomRd),d0		; Get mid-read bit
		move.w	#0,(z80_bus).l			; Resume Z80
		tst.b	d0
		beq.s	.safe
		moveq	#68,d0
		dbf	d0,*
		bra.s	.retry
.safe:
		move.w	(sp)+,sr
		rts

; --------------------------------------------------------
; Sound_DMA_Resume
; 
; Call this after finishing DMA
; --------------------------------------------------------

Sound_DMA_Resume:
		move.w	sr,-(sp)
		or.w	#$700,sr
		bsr	sndLockZ80
		move.b	#0,(z80_cpu+commZRomBlk)
		bsr	sndUnlockZ80
		move.w	(sp)+,sr
		rts

; --------------------------------------------------------
; Sound_Request_Word
; 
; d0    - request id
; d1-d5 - arguments
; --------------------------------------------------------

SoundReq_SetSample:
		bsr	sndReq_Enter
		move.w	#$21,d7
		bsr	sndReq_scmd
		move.l	d0,d7
		bsr	sndReq_saddr
		move.l	d1,d7
		bsr	sndReq_saddr
		move.l	d2,d7
		bsr	sndReq_saddr
		move.l	d3,d7
		bsr	sndReq_sword
		bra 	sndReq_Exit
Sound_Request:
		bsr	sndReq_Enter
		move.w	d0,d7
		bsr	sndReq_scmd
		move.l	d1,d7
		bsr	sndReq_sword
		bra 	sndReq_Exit

; ------------------------------------------------
; Lock Z80, get bus
; ------------------------------------------------

sndLockZ80:
		move.w	#$0100,(z80_bus).l		; Stop Z80
.wait:
		btst	#0,(z80_bus).l			; Wait for it
		bne.s	.wait
		rts
		
; ------------------------------------------------
; Unlock Z80, return bus
; ------------------------------------------------

sndUnlockZ80:
		move.w	#0,(z80_bus).l
		rts
sndSendCmd:
		rts

; ------------------------------------------------
; 68k-to-z80 Sound request
; enter/exit routines
; ------------------------------------------------

sndReq_Enter:
		movem.l	d6-d7/a5-a6,(RAM_SoundLastReg).l
		moveq	#0,d6
		move.w	sr,d6
		swap	d6
		move.w	#$0100,(z80_bus).l		; Stop Z80
		or.w	#$0700,sr			; disable ints
		lea	(z80_cpu+commZWrite),a5		; a5 - commZWrite
		lea	(z80_cpu+commZfifo),a6		; a6 - fifo command list
.wait:
		btst	#0,(z80_bus).l			; Wait for Z80
		bne.s	.wait
		move.b	(a5),d6				; d6 - index fifo position
		ext.w	d6				; extend to 16 bits
		rts
; JUMP ONLY
sndReq_Exit:
		move.w	#0,(z80_bus).l
		swap	d6
		move.w	d6,sr
		movem.l	(RAM_SoundLastReg).l,d6-d7/a5-a6
		rts
		
; ------------------------------------------------
; Send request id and arguments
;
; Input:
; d7 - byte to write
; d6 - index pointer
; a5 - commZWrite, update index
; a6 - commZfifo command list
; 
; *** CALL sndReq_Enter FIRST ***
; ------------------------------------------------

sndReq_scmd:
		move.b	#-1,(a6,d6.w)			; write command-start flag
		addq.b	#1,d6				; next fifo pos
		andi.b	#$3F,d6
		bra.s	sndReq_sbyte
sndReq_slong:
		bsr	sndReq_sbyte
		ror.l	#8,d7
sndReq_saddr:
		bsr	sndReq_sbyte
		ror.l	#8,d7
sndReq_sword:
		bsr	sndReq_sbyte
		ror.l	#8,d7
sndReq_sbyte:
		move.b	d7,(a6,d6.w)			; write byte
		addq.b	#1,d6				; next fifo pos
		andi.b	#$3F,d6
		move.b	d6,(a5)				; update commZWrite
		rts

; ====================================================================
; ----------------------------------------------------------------
; Z80 Code
; 
; GEMA sound driver, inspired by GEMS
; 
; WARNING: The sample playback is sync'd manually on every
; code change, DAC sample rate is 16000hz base
; ----------------------------------------------------------------

		align $100
Z80_CODE:
		cpu Z80				; [AS] Set to Z80
		phase 0				; [AS] Reset PC to zero, for this section

; --------------------------------------------------------
; Variables
; --------------------------------------------------------

; To brute force DAC playback on/off
zopcEx		equ	08h
zopcNop		equ	00h
zopcRet		equ 	0C9h
zopcExx		equ	0D9h			; (dac_me ONLY)
zopcPushAf	equ	0F5h			; (dac_fill ONLY)

; PSG control
COM		equ	0
LEV		equ	4
ATK		equ	8
DKY		equ	12
SLV		equ	16
RRT		equ	20
MODE		equ	24
DTL		equ	28
DTH		equ	32
ALV		equ	36
FLG		equ	40
			      
; --------------------------------------------------------
; Macros
; --------------------------------------------------------

; only uses A
dacStream	macro option
	if option==True
		ld	a,2Bh
		ld	(Zym_ctrl_1),a
		ld	a,80h
		ld	(Zym_data_1),a
		ld 	a,zopcExx
		ld	(dac_me),a
		ld 	a,zopcPushAf
		ld	(dac_fill),a
	else
		ld	a,2Bh
		ld	(Zym_ctrl_1),a
		ld	a,00h
		ld	(Zym_data_1),a
		ld 	a,zopcRet
		ld	(dac_me),a
		ld 	a,zopcRet
		ld	(dac_fill),a
	endif
		endm
		
; ====================================================================

		di				; Disable interrputs
		im	1			; Interrupt mode 1
		ld	sp,2000h		; Set stack at the end of Z80
		jr	z80_init		; Jump to z80_init
		
testval1	dw 0
testval2	dw 0

; --------------------------------------------------------
; Z80 Interrupt at 0038h
; 
; Requests a TICK
; --------------------------------------------------------

		org 0038h			; Align to 0038h
		ld	(tickFlag),sp		; Use sp to set TICK request (Sets xx1F)
		di				; Disable interrupt until next request
		ret

; --------------------------------------------------------
; Initilize
; --------------------------------------------------------

z80_init:
		call	gema_init		; Initilize VBLANK sound driver
; 		call	dac_play
		ei
		
; --------------------------------------------------------
; MAIN LOOP
; --------------------------------------------------------

drv_loop:
		call	dac_me
		call	check_tick		; Check for tick on VBlank
		call	dac_fill
		call	dac_me

	; Check for tick and tempo	
		ld	b,0			; b - Reset current flags (beat|tick)
		ld	a,(tickCnt)		
		sub	1
		jr	c,.noticks
		ld	(tickCnt),a
		call	psg_env			; Do PSG effects
		call	check_tick		; Check for another tick
		ld 	b,1			; Set TICK (01b) flag
.noticks:
		call	dac_me
		ld	a,(sbeatAcc+1)		; check beat counter (scaled by tempo)
		sub	1
		jr	c,.nobeats
		ld	(sbeatAcc+1),a		; 1/24 beat passed.
		set	1,b			; Set BEAT (10b) flag
		call	dac_me			; painful desync here, play 3 WAV bytes
		call	dac_me
		call	dac_me
.nobeats:
		ld	a,b
		or	a
		jr	z,.neithertick
		call	dac_me
		ld	(currTickBits),a	; Save bits
; 		call	doenvelope
		call	check_tick
; 		call	vtimer
		call	check_tick
; 		call	updseq
		call	check_tick
; 
.neithertick:
; 		call	apply_bend
; 		ld	b,7
; 		djnz	$
; 		call	dac_me

.next_cmd:
		ld	a,(commZWrite)
		ld	b,a
		ld	a,(commZRead)
		cp	b
		jp	z,drv_loop

	; Get 0FFh (Start of command)
		call	get_cmdbyte		; read cmd from CMDFIFO
		cp	-1
		jp	nz,drv_loop
		call	get_cmdbyte
		add	a,a
		ld	hl,.list
		ld	d,0
		ld	e,a
		add	hl,de
		call	dac_me
		call	dac_fill
		ld	a,(hl)
		inc	hl
		ld	h,(hl)
		ld	l,a
		jp	(hl)
.list:
		dw .cmnd_0		; $00
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0		; $04
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0		; $08
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0		; $0C
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0		; $10
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0		; $14
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0		; $18
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0		; $1C
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0		; $20
		dw .cmnd_wav_set	; $21
		dw .cmnd_wav_pitch	; $22	

; --------------------------------------------------------
; Command list
; --------------------------------------------------------

.cmnd_0:
		jr	$
		jp	.next_cmd

; --------------------------------------------------------
; $21 - change current wave pitch
; --------------------------------------------------------

.cmnd_wav_set:
		ld	ix,wave_Start
		call	get_cmdbyte
		ld	(ix),a
		inc	ix
		call	get_cmdbyte
		ld	(ix),a
		inc	ix
		call	get_cmdbyte
		ld	(ix),a
		inc	ix
; 
		call	get_cmdbyte
		ld	(ix),a
		inc	ix
		call	get_cmdbyte
		ld	(ix),a
		inc	ix
		call	get_cmdbyte
		ld	(ix),a
		inc	ix
; 		
		call	get_cmdbyte
		ld	(ix),a
		inc	ix
		call	get_cmdbyte
		ld	(ix),a
		inc	ix
		call	get_cmdbyte
		ld	(ix),a
		inc	ix

		call	get_cmdbyte
		ld	(ix),a
		inc	ix
		call	get_cmdbyte
		ld	(ix),a
		inc	ix
		
		ld	a,101b
		ld	(ix),a
		
		call	dac_play
		jp	.next_cmd

; --------------------------------------------------------
; $22 - change current wave pitch
; --------------------------------------------------------

.cmnd_wav_pitch:
		exx
		push	de
		exx
		pop	hl
		call	dac_me
		call	get_cmdbyte	; $00xx
		ld	e,a
		call	get_cmdbyte	; $xx00
		ld	d,a
		push	de
		call	dac_me
		exx
		pop	de
		exx
		jp	drv_loop
		
; ====================================================================
; ----------------------------------------------------------------
; Sound playback code
; ----------------------------------------------------------------

; --------------------------------------------------------
; Init sound engine
; --------------------------------------------------------

gema_init:
		dacStream False
		ld	a,09Fh
		ld	(Zpsg_ctrl),a
		ld	a,0BFh
		ld	(Zpsg_ctrl),a		
		ld	a,0DFh
		ld	(Zpsg_ctrl),a	
		ld	a,0FFh
		ld	(Zpsg_ctrl),a
		ld	de,2700h
		call	SndDrv_FmSet_1
		ld	de,2800h
		call	SndDrv_FmSet_1
		ld	de,2801h
		call	SndDrv_FmSet_1
		ld	de,2802h
		call	SndDrv_FmSet_1
		ld	de,2804h
		call	SndDrv_FmSet_1
		ld	de,2805h
		call	SndDrv_FmSet_1
		ld	de,2806h
		call	SndDrv_FmSet_1
		ld	de,2B00h
		call	SndDrv_FmSet_1	
		ld	hl,dWaveBuff			; Initilize WAVE FIFO
		ld	de,dWaveBuff+1
		ld	bc,100h-1
		ld	(hl),80h
		ldir
		ret
		
; ====================================================================
; ----------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------

get_cmdbyte:
		push	bc
		push	de
		push	hl
.getcbytel:
		call	dac_me
		call	dac_fill
		ld	a,(commZWrite)
		ld	b,a
		ld	a,(commZRead)
		cp	b
		jp	z,.getcbytel		; wait for a command from 68k
		ld	b,0
		ld	c,a
		ld	hl,commZfifo
		call	dac_me
		add	hl,bc
		inc	a
		and	3Fh			; limit to 64
		ld	(commZRead),a
		ld	a,(hl)
		pop	hl
		pop	de
		pop	bc
		ret
			      
; --------------------------------------------------------
; check_tick
; 
; Checks if VBlank triggred a TICK (1/150)
; --------------------------------------------------------

check_tick:
		di				; Disable ints
		push	af
		push	hl
		ld	hl,tickFlag+1		; read last TICK flag
		ld	a,(hl)			; non-zero value?
		or 	a
		jr	z,.ctnotick

	; ints are disabled from here
		ld	(hl),0			; Reset TICK flag
		inc	hl			; Move to tickCnt
		inc	(hl)			; and increment
		call	dac_me
		push	de
		ld	hl,(sbeatAcc)		; Increment subbeats
		ld	de,(sbeatPtck)
		call	dac_me
		add	hl,de
		ld	(sbeatAcc),hl
		pop	de
		call	dac_me
		call	dac_fill
.ctnotick:
		pop	hl
		pop	af
		ei				; Enable ints again
		ret

; --------------------------------------------------------
; set_tempo
; 
; Input:
; a - Beats per minute
;
; Uses:
; de,hl
; --------------------------------------------------------

set_tempo:
		ld	de,218
		call	do_multiply
		xor	a
		sla	l
		rl	h
		rla			; AH <- sbpt, 8 fracs
		ld	l,h
		ld	h,a		; HL <- AH
		ld	(sbeatPtck),hl
		ret

; ---------------------------------------------
; do_multiply
; 
; Input:
; hl - Start from
; de - Multply by this
; ---------------------------------------------

; 			      ; GETPATPTR
; 			      ; 		ld	HL,PATCHDATA
; 	dc.b	$21,$86,$18
; 			      ; 		ld	DE,39
; 	dc.b	$11,$27,$00
; 			      ; 		jr	MULADD
; 	dc.b	$18,$03

do_multiply:
		ld	hl,0
.mul_add:
		srl	a
		jr	nc,.mulbitclr
		add	hl,de
.mulbitclr:
		ret	z
		sla	e		; if more bits still set in A, DE*=2 and loop
		rl	d
		jr	.mul_add

; --------------------------------------------------------

CHBUFPTR	dw	0			; pointer to current channel's sequence buffer
CHPATPTR	dw	0			; pointer to current channel's patch buffer
updseq:
		ld	ix,CCB
		ld	hl,CH0BUF
		ld	(CHBUFPTR),hl
; 		ld 	hl,PATCHDATA
		ld	(CHPATPTR),hl
		ld	a,(currTickBits)
		ld	c,a
		ld	a,16
		ld	b,0
		jr	.updseqloop1
.updseqloop:
		call	dac_me
		ld	de,32
		add	ix,de
		ld	hl,(CHBUFPTR)
		ld	e,16
		add	hl,de
		ld	(CHBUFPTR),hl
		ld	hl,(CHPATPTR)
		ld	e,39
		add	hl,de
		ld	(CHPATPTR),hl
.updseqloop1:
		bit	4,(IX+CCBFLAGS)				; paused or free?
		jr	z,.updseqloop2
		bit	3,(IX+CCBFLAGS)				; sfx tempo bit?
		jr	nz,.updseqsfx
		bit	1,c
		jr	nz,.updseqdoit
		jr	.updseqloop2
.updseqsfx:
		bit	0,c
		jr	z,.updseqloop2
.updseqdoit:
		call	dac_me
		push	af
		push	bc
		call	dac_refill
; 		call	sequencer
		pop	bc
		pop	af
.updseqloop2:
		inc	b
		dec	a
		jr	nz,.updseqloop
		ret
apply_bend:
		ret

; --------------------------------------------------------
; transferRom
; 
; Transfer bytes from ROM to Z80
; 
; Input:
; a  - Source ROM address $xx0000
; bc - Byte count (0000h NOT allowed)
; hl - Source ROM address $00xxxx
; de - Destination address
; 
; Uses:
; b, ix
; 
; Notes:
; call dac_fill first if transfering data
; other than WAV sample data, just to be safe
; --------------------------------------------------------

transferRom:
		call	dac_me
		push	ix
		ld	ix,commZRomBlk
		ld	(x68ksrclsb),hl
		res	7,h
		ld	b,0
		dec	c
		add	hl,bc
		bit	7,h
		jr	nz,.double
		ld	hl,(x68ksrclsb)		; single transfer
		inc	c
		ld	b,a
		call	.transfer
		pop	ix
		ret
.double:
		ld	b,a			; double transfer
		push	bc
		push	hl
		ld	a,c
		sub	a,l
		ld	c,a
		ld	hl,(x68ksrclsb)
		call	.transfer
		pop	hl
		pop	bc
		ld	c,l
		inc	c
		ld	a,(x68ksrcmid)
		and	80h
		add	a,80h
		ld	h,a
		ld	l,0
		jr	nc,.x68knocarry
		inc	b
.x68knocarry:
		call	.transfer
		pop	ix
		ret

; b  - Source ROM xx0000
;  c - Bytes to transfer (00h not allowed)
; hl - Source ROM 00xxxx
; de - Destination address
; 
; Uses:
; a
.transfer:
		call	dac_me
		push	de
		ld	de,6000h
		ld	a,h
		rlc	a
		ld	(de),a
		ld	a,b
		ld	(de),a
		rra
		ld	(de),a
		rra
		ld	(de),a
		rra
		call	dac_me
		ld	(de),a
		rra
		ld	(de),a
		rra
		ld	(de),a
		rra
		ld	(de),a
		rra
		ld	(de),a
		pop	de
		set	7,h
		call	dac_me
	; Transfer data in parts of 3bytes
	; while playing cache'd WAV in the process
		ld	a,c
		ld	b,0
		set	0,(ix+1)	; Tell to 68k that we are reading from ROM
		sub	a,3
		jr	c,.x68klast
.x68kloop:
		ld	c,3-1
		bit	0,(ix)		; If 68k requested ROM block from here
		jr	nz,.x68klpwt
.x68klpcont:
		ldir
		nop
		call	dac_me
		nop
		sub	a,3-1
		jp	nc,.x68kloop
; last block
.x68klast:
		add	a,3
		ld	c,a
		bit	0,(ix)		; If 68k requested ROM block from here
		jp	nz,.x68klstwt
.x68klstcont:
		ldir
		call	dac_me
		res	0,(ix+1)
		ret

; If 68k requests uses DMA
; NOTE: This MIGHT cause the DAC to run out
; of sample data
.x68klpwt:
		res	0,(ix+1)		; Not reading ROM
.x68kpwtlp:
		nop
		call	dac_me
		nop
		bit	0,(ix)			; Is ROM free from 68K?
		jr	nz,.x68kpwtlp
		set	0,(ix+1)		; Reading ROM again.
		jr	.x68klpcont
; Last write
.x68klstwt:
		res	0,(ix+1)		; Not reading ROM
.x68klstwtlp:
		nop
		call	dac_me
		nop
		bit	0,(ix)			; Is ROM free from 68K?
		jr	nz,.x68klstwtlp
		set	0,(ix+1)		; Reading ROM again.
		jr	.x68klstcont

; ====================================================================
; ----------------------------------------------------------------
; Sound chip routines
; ----------------------------------------------------------------

; --------------------------------------------------------
; psg_env
; 
; Processes the PSG manuall to add effects
; --------------------------------------------------------

psg_env:
		ld	iy,psgcom
		ld	ix,PSGVTBLTG3		; Byte for Unlocking PSG3
		ld	hl,Zpsg_ctrl
		ld	d,80h			; PSG first ctrl command
		ld	e,4			; 4 channels
.vloop:
		call	dac_me
		ld	c,(iy+COM)		; c - current command
		ld	(iy+COM),0		; clear for the next one
	; bit 2 - stop sound
		bit	2,c			; bit 2?
		jr	z,.ckof
		ld	(iy+LEV),-1		; reset level
		ld	(iy+FLG),1		; and update
		ld	(iy+MODE),0		; envelope off
		ld	a,1			; PSG Channel 3?
		cp	e
		jr	nz,.ckof
		res	5,(ix)			; Unlock PSG3
.ckof:
	; bit 1 - key off
		bit	1,c			; bit 1?
		jr      z,.ckon
		ld	a,(iy+MODE)		; envelope mode 0?
		cp	0
		jr	z,.ckon
		ld	(iy+FLG),1		; psg update flag
		ld	(iy+MODE),4		; set envelope mode 4
.ckon:
	; bit 0 - key on
		bit	0,c			; bit 0?
		jr	z,.envproc
		ld	(iy+LEV),-1		; reset level
		ld	a,(iy+DTL)		; load frequency LSB or NOISE data
		or	d			; OR with current channel
		ld	(hl),a			; write it
		ld	a,1			; NOISE channel?
		cp	e
		jr	z,.nskip		; then don't write next one
		ld	a,(iy+DTH)		; Write PSG MSB frequency (1-3 only)
		ld	(hl),a
.nskip:
		ld	(iy+FLG),1		; psg update flag
		ld	(iy+MODE),1		; set to attack mode
	
	; ----------------------------
	; Start processing
	; current PSG channel
	; ----------------------------
.envproc:
		call	dac_me
		ld	a,(iy+MODE)
		or	a			; no modes
		jp	z,.vedlp
		
	; Attack mode
		cp 	001b
		jr	nz,.chk2
.mode1:
		ld	(iy+FLG),1		; psg update flag
		ld	a,(iy+LEV)		; a - current level (volume)
		ld	b,(iy+ALV)		; b - attack level
		sub	a,(iy+ATK)		; (attack rate) - (level)
		jr	c,.atkend		; attack finished
		jr	z,.atkend
		cp	b			; check level
		jr	c,.atkend		; attack finished
		jr	z,.atkend		
		ld	(iy+LEV),a		; set new level
		jp	.vedlp
.atkend:
		ld	(iy+LEV),b		; attack level = new level
		ld	(iy+MODE),2		; set to decay mode
		jp	.vedlp
.chk2:

	; Decay mode
		cp	010b
		jp	nz,.chk4
		ld	(iy+FLG),1		; psg update flag
		ld	a,(iy+LEV)		; a - Level
		ld	b,(iy+SLV)		; b - Sustain
		cp	b
		jr	c,.dkadd		; if carry: add
		jr	z,.dkyend		; if zero:  finish
		sub	(iy+DKY)		; substract decay rate
		jr	c,.dkyend		; finish if wraped.
		cp	b			; compare level
		jr	c,.dkyend		; and finish
		jr	.dksav
.dkadd:
		add	a,(iy+DKY)		;  (level) + (decay rate)
		jr	c,.dkyend		; finish if wraped.
		cp	b			; compare level
		jr	nc,.dkyend
.dksav:
		ld	(iy+LEV),a		; save new level
		jr	.vedlp
.dkyend:
		ld	(iy+LEV),b		; save sustain value
		ld	(iy+MODE),3		; and set mode too.
		jr	.vedlp

	; Sustain phase
.chk4:
		cp	100b
		jr	nz,.vedlp
		ld	(iy+FLG),1		; psg update flag
		ld	a,(iy+LEV)		; a - Level
		add 	a,(iy+RRT)		; add Release Rate
		jr	c,.killenv		; release done
		ld	(iy+LEV),a		; set new Level
		jr	.vedlp
.killenv:
		ld	(iy+LEV),-1		; Silence this channel
		ld	(iy+MODE),0		; Reset mode
		ld	a,1			; PSG Channel 3?
		cp	e
		jr	nz,.vedlp
		res	5,(ix)			; Unlock PSG3
.vedlp:
		inc	iy			; next COM to check
		ld	a,20h			; next PSG channel
		add	a,d
		ld	d,a
		dec	e
		jp	nz,.vloop

	; ----------------------------
	; Set volumes
		call	dac_me
		ld	iy,psgcom
		ld	ix,Zpsg_ctrl
		ld	hl,90h		; Channel + volumeset bit
		ld	de,20h		; next channel increment
		ld	b,4
.nextpsg:
		bit	0,(iy+FLG)	; PSG update?
		jr	z,.flgoff
		ld	(iy+FLG),0	; Reset until next one
		ld	a,(iy+LEV)	; a - Level
		srl	a		; (Level >> 4)
		srl	a
		srl	a
		srl	a
		or	l		; merge Channel bits
		ld	(ix),a		; Write volume
.flgoff:
		add	hl,de		; next channel
		inc	iy		; next com
		djnz	.nextpsg
		call	dac_me
		ret

; ---------------------------------------------
; FM send registers
; 
; Input:
; d - ctrl
; e - data
; c - channel
; ---------------------------------------------

SndDrv_FmSet_1:
		ld	a,d
		ld	(Zym_ctrl_1),a
		nop
		ld	a,e
		ld	(Zym_data_1),a
		nop
		ret

SndDrv_FmSet_2:
		ld	a,d
		ld	(Zym_ctrl_2),a
		nop
		ld	a,e
		ld	(Zym_data_2),a
		nop	
		ret

; --------------------------------------------------------
; dac_play
; 
; Plays a new sample
; --------------------------------------------------------

dac_play:
		di
		dacStream False
		exx
		ld	bc,dWaveBuff>>8			; bc - WAVFIFO MSB
		ld	de,(wave_Pitch)			; de - Pitch
		ld	hl,(dWaveBuff&0FFh)<<8		; hl - WAVFIFO LSB pointer (xx.00)
		exx
		ld	hl,(wave_Start)
		ld 	a,(wave_Start+2)
		ld	(dDacPntr),hl
		ld	(dDacPntr+2),a
		ld	hl,(wave_End)
		ld 	a,(wave_End+2)
		ld	(dDacCntr),hl
		ld	(dDacCntr+2),a
		xor	a
		ld	(dDacFifoMid),a
		call	dac_firstfill
		dacStream True
		ei
		ret

; --------------------------------------------------------
; dac_me
; 
; Writes wave data to DAC using data stored on buffer.
; Call this routine every 6 or more lines of code
; (use any emu-debugger to check if it still plays
; at stable 16000hz)
;
; Input (EXX):
;  c - WAVEFIFO MSB
; de - Pitch (xx.00)
; h  - WAVEFIFO LSB (as xx.00)
; 
; Uses (EXX):
; b
; 
; *** self-modifiable code ***
; --------------------------------------------------------

dac_me:		exx				; <-- self-changes between EXX(play) and RET(stop)
		ex	af,af'
		ld	b,l
		ld	a,2Ah
		ld	(Zym_ctrl_1),a
		ld	l,h
		ld	h,c
		ld	a,(hl)
		ld	(Zym_data_1),a
		ld	h,l
		ld	l,b
		add	hl,de
		ex	af,af'
		exx
		ret

; --------------------------------------------------------
; dac_fill
; 
; Refills a half of the WAVE FIFO data, automatic
; 
; *** self-modifiable code ***
; --------------------------------------------------------

dac_fill:	push	af			; <-- self-changes between PUSH AF(play) and RET(stop)
		ld	a,(dDacFifoMid)
		exx
		xor	h			; xx.00
		exx
		and	80h
		jp	nz,dac_refill
		pop	af
		ret
; first time
dac_firstfill:
		call	check_tick
		push	af

; If auto-fill is needed
; TODO: improve this.
dac_refill:
		call	dac_me
		push	bc
		push	de
		push	hl
		ld	a,(wav_Flags)
		cp	111b
		jp	nc,.FDF7

		ld	a,(dDacCntr+2)
		ld	hl,(dDacCntr)
		ld	bc,80h
		scf
		ccf
		sbc	hl,bc
		sbc	a,0
		ld	(dDacCntr+2),a
		ld	(dDacCntr),hl
		ld	d,dWaveBuff>>8
		or	a
		jp	m,.FDF4DONE
; 		jr	c,.FDF4DONE
; 		jr	z,.FDF4DONE
.keepcntr:

		ld	a,(dDacFifoMid)
		ld	e,a
		add 	a,80h
		ld	(dDacFifoMid),a
		ld	hl,(dDacPntr)
		ld	a,(dDacPntr+2)
		call	transferRom
		ld	hl,(dDacPntr)
		ld	a,(dDacPntr+2)
		ld	bc,80h
		add	hl,bc
		adc	a,0
		ld	(dDacPntr),hl
		ld	(dDacPntr+2),a
		jp	.FDFreturn
.FDF4DONE:
		ld	d,dWaveBuff>>8
		ld	a,(wav_Flags)
		cp	101b
		jp	z,.FDF72
		
		ld	a,l
		add	a,80h
		ld	c,a
		ld	b,0
		push	bc
		ld	a,(dDacFifoMid)
		ld	e,a
		add	a,80h
		ld	(dDacFifoMid),a
		pop	bc			; C <- # just xfered
		ld	a,c
		or	b
		jr	z,.FDF7
		ld	hl,(dDacPntr)
		ld	a,(dDacPntr+2)
		call	transferRom
		jr	.FDF7
.FDF72:

	; loop sample
		push	bc
		push	de
		ld	a,(wave_Loop+2)
		ld	c,a
		ld	de,(wave_Loop)
		ld	hl,(wave_Start)
		ld 	a,(wave_Start+2)
		add	a,c
		add	hl,de
		adc	a,0
		ld	(dDacPntr),hl
		ld	(dDacPntr+2),a
		ld	hl,(wave_End)
		ld 	a,(wave_End+2)
		sub	a,c
		scf
		ccf
		sbc	hl,de
		sbc	a,0
		ld	(dDacCntr),hl
		ld	(dDacCntr+2),a
		pop	de
		pop	bc
		ld	a,b
		or	c
		jr	z,.FDFreturn
		ld	a,(dDacFifoMid)
		ld	e,a
		add	a,80h
		ld	(dDacFifoMid),a
		ld	hl,(dDacPntr)
		ld	a,(dDacPntr+2)
		call	transferRom
		jr	.FDFreturn
.FDF7:
		dacStream False
.FDFreturn:
		pop	hl
		pop	de
		pop	bc
		pop	af
		ret
			      
; ====================================================================
; ----------------------------------------------------------------
; Tables
; ----------------------------------------------------------------

wavFreq_List:	dw 100h		; C-0
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h	
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h		; C-1
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h	
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h		; C-2
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 03Bh
		dw 03Eh		; C-3 5512
		dw 043h		; C#3
		dw 046h		; D-3
		dw 049h		; D#3
		dw 04Eh		; E-3
		dw 054h		; F-3
		dw 058h		; F#3
		dw 05Eh		; G-3 8363 -17
		dw 063h		; G#3
		dw 068h		; A-3
		dw 070h		; A#3
		dw 075h		; B-3
		dw 07Fh		; C-4 11025 -12
		dw 088h		; C#4
		dw 08Fh		; D-4
		dw 097h		; D#4
		dw 0A0h		; E-4
		dw 0ADh		; F-4
		dw 0B5h		; F#4
		dw 0C0h		; G-4
		dw 0CCh		; G#4
		dw 0D7h		; A-4
		dw 0E7h		; A#4
		dw 0F0h		; B-4
		dw 100h		; C-5 22050
		dw 110h		; C#5
		dw 120h		; D-5
		dw 12Ch		; D#5
		dw 142h		; E-5
		dw 158h		; F-5
		dw 16Ah		; F#5 32000 +6
		dw 17Eh		; G-5
		dw 190h		; G#5
		dw 1ACh		; A-5
		dw 1C2h		; A#5
		dw 1E0h		; B-5
		dw 1F8h		; C-6 44100 +12
		dw 210h		; C#6
		dw 240h		; D-6
		dw 260h		; D#6
		dw 280h		; E-6
		dw 2A0h		; F-6
		dw 2D0h		; F#6
		dw 2F8h		; G-6
		dw 320h		; G#6
		dw 350h		; A-6
		dw 380h		; A#6
		dw 3C0h		; B-6
		dw 400h		; C-7 88200
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h	
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h	
		dw 100h		; C-8
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h	
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h	
		dw 100h		; C-9
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h	
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h

fmFreq_List:	dw 644		; C-0
		dw 681
		dw 722
		dw 765
		dw 810
		dw 858
		dw 910
		dw 964
		dw 1021
		dw 1081
		dw 1146
		dw 1214

psgFreq_List:
		dw -1		; C-0 $0
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1		; C-1 $C
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1		; C-2 $18
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1		; C-3 $24
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw 3F8h
		dw 3BFh
		dw 389h
		dw 356h		;C-4 30
		dw 326h
		dw 2F9h
		dw 2CEh
		dw 2A5h
		dw 280h
		dw 25Ch
		dw 23Ah
		dw 21Ah
		dw 1FBh
		dw 1DFh
		dw 1C4h
		dw 1ABh		;C-5 3C
		dw 193h
		dw 17Dh
		dw 167h
		dw 153h
		dw 140h
		dw 12Eh
		dw 11Dh
		dw 10Dh
		dw 0FEh
		dw 0EFh
		dw 0E2h
		dw 0D6h		;C-6 48
		dw 0C9h
		dw 0BEh
		dw 0B4h
		dw 0A9h
		dw 0A0h
		dw 97h
		dw 8Fh
		dw 87h
		dw 7Fh
		dw 78h
		dw 71h
		dw 6Bh		; C-7 54
		dw 65h
		dw 5Fh
		dw 5Ah
		dw 55h
		dw 50h
		dw 4Bh
		dw 47h
		dw 43h
		dw 40h
		dw 3Ch
		dw 39h
		dw 36h		; C-8 $60
		dw 33h
		dw 30h
		dw 2Dh
		dw 2Bh
		dw 28h
		dw 26h
		dw 24h
		dw 22h
		dw 20h
		dw 1Fh
		dw 1Dh
		dw 1Bh		; C-9 $6C
		dw 1Ah
		dw 18h
		dw 17h
		dw 16h
		dw 15h
		dw 13h
		dw 12h
		dw 11h
 		dw 10h
 		dw 9h
 		dw 8h
		dw 0		; use +60 if using C-5 for tone 3 noise

; ====================================================================
; ----------------------------------------------------------------
; Z80 RAM
; ----------------------------------------------------------------

; ************************************* SEQUENCER CODE ***************************************
; 
; * CCB Entries:
; *		2,1,0	tag addr of 1st byte in 32-byte channel buffer
; *		5,4,3	addr of next byte to fetch
; *				so: 0 <= addr-tag <= 31 means hit in buffer
; *		6	flags
; *		8,7	timer (contains 0-ticks to delay)
; *		10,9	delay
; *		12,11	duration
; 
CCBTAGL		equ	0	; lsb of addr of 1st byte in 32-byte sequence buffer
CCBTAGM		equ	1	; mid of "
CCBTAGH		equ	2	; msb of "
CCBADDRL	equ	3	; lsb of addr of next byte to read from sequence
CCBADDRM	equ	4	; mid of "
CCBADDRH	equ	5	; msb of "
CCBFLAGS	equ	6	; 80 = sustain
				; 40 = env retrigger
				; 20 = lock (for 68k based sfx)
				; 10 = running (not paused)
				; 08 = use sfx (150 bpm) timebase
				; 02 = muted (running, but not executing note ons)
				; 01 = in use
CCBTIMERL	equ	7	; lsb of 2's comp, subbeat (1/24th) timer till next event
CCBTIMERH	equ	8	; msb of "
CCBDELL		equ	9	; lsb of registered subbeat delay value
CCBDELH		equ	10	; msb of "
CCBDURL		equ	11	; lsb of registered subbeat duration value
CCBDURH		equ	12	; msb of "
CCBPNUM		equ	13	; program number (patch)
CCBSNUM		equ	14	; sequence number (in sequence bank)
CCBVCHAN	equ	15	; MIDI channel number within sequence CCBSNUM
CCBLOOP0	equ	16	; loop stack (counter, lsb of start addr, mid of start addr)
CCBLOOP1	equ	19
CCBLOOP2	equ	22
CCBLOOP3	equ	25
CCBPRIO		equ	28	; priority (0 lowest, 127 highest)
CCBENV		equ	29	; envelope number
CCBATN		equ	30	; channel attenuation (0=loud, 127=quiet)
CCBy		equ	31

; --------------------------------------------------------
; Internal
; --------------------------------------------------------

		align 100h
dWaveBuff	ds 100h			; WAVE data buffer, updated by 128bytes
commZfifo	ds 64			; Buffer for command requests

MBOXES		ds 32			; GEMS mailboxes
CCB		ds 512			; CCB - 512 bytes
CH0BUF		ds 256			; channel cache - 256 bytes

tickFlag	dw 0			; Tick flag (from VBlank), Use tickFlag+1 for reading/reseting
tickCnt		db 0			; Tick counter (KEEP THIS TAG AFTER tickFlag)
sbeatPtck	dw 204			; sub beats per tick (8frac), default is 120bpm
sbeatAcc	dw 0			; accumulates ^^ each tick to track sub beats
currTickBits	db 0			; (old: TBASEFLAGS)		      
dDacPntr	db 0,0,0		; WAVE current ROM position
dDacCntr	db 0,0,0		; WAVE length counter
dDacFifoMid	db 0			; WAVE current FIFO next halfway section
x68ksrclsb	db 0
x68ksrcmid	db 0
commZRead	db 0			; read pointer (here)
commZWrite	db 0			; cmd fifo wptr (from 68k)
commZRomBlk	db 0			; 68k ROM block flag
commZRomRd	db 0			; Z80 is reading ROM bit

psgcom		db 00h,00h,00h,00h	;  0 command 1 = key on, 2 = key off, 4 = stop snd
psglev		db  -1, -1, -1, -1	;  4 output level attenuation (4 bit)
psgatk		db 00h,00h,00h,00h	;  8 attack rate
psgdec		db 00h,00h,00h,00h	; 12 decay rate
psgslv		db 00h,00h,00h,00h	; 16 sustain level attenuation
psgrrt		db 00h,00h,00h,00h	; 20 release rate
psgenv		db 00h,00h,00h,00h	; 24 envelope mode 0 = off, 1 = attack, 2 = decay, 3 = sustain, 4
psgdtl		db 00h,00h,00h,00h	; 28 tone bottom 4 bits, noise bits
psgdth		db 00h,00h,00h,00h	; 32 tone upper 6 bits
psgalv		db 00h,00h,00h,00h	; 36 attack level attenuation
whdflg		db 00h,00h,00h,00h	; 40 flags to indicate hardware should be updated

; dynamic chip allocation
FMVTBL		db 080H,0,050H,0,0,0,0	; fm voice 0
		db 081H,0,050H,0,0,0,0	; fm voice 1
		db 084H,0,050H,0,0,0,0	; fm voice 3
		db 085H,0,050H,0,0,0,0	; fm voice 4
FMVTBLCH6	db 086H,0,050H,0,0,0,0	; fm voice 5 (FM or WAVE)
FMVTBLCH3	db 082H,0,050H,0,0,0,0	; fm voice 2 (CH3 special)
		db -1
PSGVTBL		db 080H,0,050H,0,0,0,0	; normal type voice, number 0
		db 081H,0,050H,0,0,0,0	; normal type voice, number 1
PSGVTBLTG3	db 082H,0,050H,0,0,0,0	; normal type voice, number 2
		db -1
PSGVTBLNG	db 083H,0,050H,0,0,0,0	; noise type voice, number 3
		db -1
EXVTBLCD	db 080H,0,050h,0,0,0,0
		db 081H,0,050h,0,0,0,0
		db 082H,0,050h,0,0,0,0
		db 083H,0,050h,0,0,0,0
		db 084H,0,050h,0,0,0,0
		db 085H,0,050h,0,0,0,0
		db 086H,0,050h,0,0,0,0
		db 087H,0,050h,0,0,0,0
		db -1
EXVTBLMARS	db 080H,0,050h,0,0,0,0
		db 081H,0,050h,0,0,0,0
		db 082H,0,050h,0,0,0,0
		db 083H,0,050h,0,0,0,0
		db 084H,0,050h,0,0,0,0
		db 085H,0,050h,0,0,0,0
		db 086H,0,050h,0,0,0,0
		db 087H,0,050h,0,0,0,0
		db 088H,0,050h,0,0,0,0
		db 089H,0,050h,0,0,0,0
		db 08AH,0,050h,0,0,0,0
		db 08BH,0,050h,0,0,0,0
		db 08CH,0,050h,0,0,0,0
		db 08DH,0,050h,0,0,0,0
		db 08EH,0,050h,0,0,0,0
		db 08FH,0,050h,0,0,0,0
		db -1

; --------------------------------------------------------
; WAVE playback
; 
; START: 68k direct pointer ($00xxxxxx)
;   END: sample length (endpointer-startpointer)
;  LOOP: sample position
; --------------------------------------------------------

wave_Start	dw TEST_WAV&0FFFFh
		db TEST_WAV>>16&0FFh
wave_End	dw (TEST_WAV_E-TEST_WAV)&0FFFFh
		db (TEST_WAV_E-TEST_WAV)>>16
wave_Loop	dw 0
		db 0
wave_Pitch	dw 100h				; 01.00h
wav_Flags	db 101b				; WAVE playback flags (%1xx: 01 loop / 10 no loop)

; ====================================================================
; ----------------------------------------------------------------
; GAME MUSIC/SOUND DATA GOES HERE
; ----------------------------------------------------------------

; ----------------------------------------------------
; PSG Instruments
; ----------------------------------------------------

PsgIns_00:	db 0
		db -1
PsgIns_01:	db 0,2,4,5,6
		db -1
PsgIns_02:	db 0,15
		db -1
PsgIns_03:	db 0,0,1,1,2,2,3,4,6,10,15
		db -1
PsgIns_04:	db 0,2,4,6,10
		db -1	
		align 4
		
; ----------------------------------------------------
; FM Instruments
; ----------------------------------------------------

patch_Data	;ds 40h*16
; .gsx instruments; filename,$2478,$20 ($28 for FM3 instruments)
FmIns_Fm3_OpenHat:
		binclude "data/sound/instr/fm/fm3_openhat.gsx",2478h,28h
FmIns_Fm3_ClosedHat:
		binclude "data/sound/instr/fm/fm3_closedhat.gsx",2478h,28h
FmIns_DrumKick:
		binclude "data/sound/instr/fm/drum_kick.gsx",2478h,20h
FmIns_DrumSnare:
		binclude "data/sound/instr/fm/drum_snare.gsx",2478h,20h
FmIns_DrumCloseHat:
		binclude "data/sound/instr/fm/drum_closehat.gsx",2478h,20h
FmIns_Piano_m1:
		binclude "data/sound/instr/fm/piano_m1.gsx",2478h,20h
FmIns_Bass_gum:
		binclude "data/sound/instr/fm/bass_gum.gsx",2478h,20h
FmIns_Bass_calm:
		binclude "data/sound/instr/fm/bass_calm.gsx",2478h,20h
FmIns_Bass_heavy:
		binclude "data/sound/instr/fm/bass_heavy.gsx",2478h,20h
FmIns_Bass_ambient:
		binclude "data/sound/instr/fm/bass_ambient.gsx",2478h,20h
FmIns_Brass_gummy:
		binclude "data/sound/instr/fm/brass_gummy.gsx",2478h,20h
FmIns_Flaute_1:
		binclude "data/sound/instr/fm/flaute_1.gsx",2478h,20h
FmIns_Bass_2:
		binclude "data/sound/instr/fm/bass_2.gsx",2478h,20h
FmIns_Bass_3:
		binclude "data/sound/instr/fm/bass_3.gsx",2478h,20h
FmIns_Bass_5:
		binclude "data/sound/instr/fm/bass_5.gsx",2478h,20h
FmIns_Bass_synth:
		binclude "data/sound/instr/fm/bass_synth_1.gsx",2478h,20h
FmIns_Guitar_1:
		binclude "data/sound/instr/fm/guitar_1.gsx",2478h,20h
FmIns_Horn_1:
		binclude "data/sound/instr/fm/horn_1.gsx",2478h,20h
FmIns_Organ_M1:
		binclude "data/sound/instr/fm/organ_m1.gsx",2478h,20h
FmIns_Bass_Beach:
		binclude "data/sound/instr/fm/bass_beach.gsx",2478h,20h
FmIns_Bass_Beach_2:
		binclude "data/sound/instr/fm/bass_beach_2.gsx",2478h,20h
FmIns_Brass_Cave:
		binclude "data/sound/instr/fm/brass_cave.gsx",2478h,20h
FmIns_Piano_Small:
		binclude "data/sound/instr/fm/piano_small.gsx",2478h,20h
FmIns_Trumpet_2:
		binclude "data/sound/instr/fm/trumpet_2.gsx",2478h,20h
FmIns_Bell_Glass:
		binclude "data/sound/instr/fm/bell_glass.gsx",2478h,20h
FmIns_Marimba_1:
		binclude "data/sound/instr/fm/marimba_1.gsx",2478h,20h
FmIns_Ambient_dark:
		binclude "data/sound/instr/fm/ambient_dark.gsx",2478h,20h
FmIns_Ambient_spook:
		binclude "data/sound/instr/fm/ambient_spook.gsx",2478h,20h
FmIns_Ding_toy:
		binclude "data/sound/instr/fm/ding_toy.gsx",2478h,20h

		
; ====================================================================

		cpu 68000
		padding off
		phase Z80_CODE+*
Z80_CODE_END:
		align 2
