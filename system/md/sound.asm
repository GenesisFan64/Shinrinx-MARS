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
; Routine to check if Z80 wants something from here
; 
; Call this on VBlank only.
; --------------------------------------------------------

Sound_Update:
		bsr	sndLockZ80
		bsr	sndUnlockZ80
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
; d1    - argument
; --------------------------------------------------------

Sound_Request:
		bsr	sndReq_Enter
		move.w	d0,d7
		bsr	sndReq_scmd
		move.l	d1,d7
		bsr	sndReq_sword
		bra 	sndReq_Exit

; --------------------------------------------------------
; SoundReq_SetTrack
; 
; d0 - Pattern data pointer
; d1 - Block data pointer
; d2 - ???
; d3 - ???
; d4 - ???
; --------------------------------------------------------

SoundReq_SetTrack:
		bsr	sndReq_Enter
		move.w	#$00,d7			; Command $00
		bsr	sndReq_scmd
		move.l	d0,d7
		bsr	sndReq_saddr
		move.l	d1,d7
		bsr	sndReq_saddr
; 		move.l	d2,d7
; 		bsr	sndReq_saddr
; 		move.l	d3,d7
; 		bsr	sndReq_sword
; 		move.l	d4,d7
; 		bsr	sndReq_sbyte
		bra 	sndReq_Exit
		
; --------------------------------------------------------
; SoundReq_SetSample
; 
; d0 - Sample pointer
; d1 - length
; d2 - loop point
; d3 - Pitch ($01.00)
; d4 - Flags (%00l l-loop enable)
; --------------------------------------------------------

SoundReq_SetSample:
		bsr	sndReq_Enter
		move.w	#$21,d7			; Command $21
		bsr	sndReq_scmd
		move.l	d0,d7
		bsr	sndReq_saddr
		move.l	d1,d7
		bsr	sndReq_saddr
		move.l	d2,d7
		bsr	sndReq_saddr
		move.l	d3,d7
		bsr	sndReq_sword
		move.l	d4,d7
		bsr	sndReq_sbyte
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
		andi.b	#$7F,d6
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
		andi.b	#$7F,d6
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

; --------------------------------------------------------
; Structs
; --------------------------------------------------------

; trkBuff struct
; LIMIT: 20h bytes
		struct 0
trk_romBlk	ds 3			; 24-bit base block data
trk_romPatt	ds 3			; 24-bit base patt data
trk_Read	ds 2			; Current track position (in cache)
trk_Rows	ds 2			; Current track length
trk_Halfway	ds 1			; Only 00h or 80h
trk_PattLen	ds 2
trk_status	ds 1			; %ERxx xxxx | E-enabled / R-Init or Restart track
		finish
		
; chnBuff
; LIMIT: 10h bytes
		struct 0
chnl_Type	ds 1			; Current type
chnl_Num	ds 1
chnl_Note	ds 1
chnl_Ins	ds 1
chnl_Vol	ds 1
chnl_EffId	ds 1
chnl_EffOpt	ds 1
chnl_Chip	ds 1
chnl_Freq	ds 2
		finish
		
; --------------------------------------------------------
; Variables
; --------------------------------------------------------

		cpu Z80			; Set Z80 here
		phase 0			; And set PC to 0
MAX_TRKS	equ	4		; Max tracks to read
MAX_CHNLS	equ	16		; Max internal track channels

; To brute force DAC playback
; on or off
zopcEx		equ	08h
zopcNop		equ	00h
zopcRet		equ 	0C9h
zopcExx		equ	0D9h		; (dac_me ONLY)
zopcPushAf	equ	0F5h		; (dac_fill ONLY)

; PSG external control
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

; ====================================================================
; --------------------------------------------------------
; Code starts here
; --------------------------------------------------------

		di			; Disable interrputs
		im	1		; Interrupt mode 1
		ld	sp,2000h	; Set stack at the end of Z80
		jr	z80_init	; Jump to z80_init

; --------------------------------------------------------
; Z80 Interrupt at 0038h
; 
; Sets the TICK flag
; --------------------------------------------------------

		org 0038h		; Align to 0038h
		ld	(tickFlag),sp	; Use sp to set TICK request (Sets xx1F)
		di			; Disable interrupt until next request
		ret

; --------------------------------------------------------
; Initilize
; --------------------------------------------------------

z80_init:
		call	gema_init	; Initilize VBLANK sound driver
; 		call	dac_play
		ei
		
; --------------------------------------------------------
; MAIN LOOP
; --------------------------------------------------------

drv_loop:
		call	dac_me
		call	check_tick	; Check for tick on VBlank
		call	dac_fill
		call	dac_me

	; Check for tick and tempo	
		ld	b,0		; b - Reset current flags (beat|tick)
		ld	a,(tickCnt)		
		sub	1
		jr	c,.noticks
		ld	(tickCnt),a
		call	psg_env		; Process PSG volume and freqs manually
		call	check_tick	; Check for another tick
		ld 	b,01b		; Set TICK (01b) flag, and clear BEAT
.noticks:
		call	dac_me
		ld	a,(sbeatAcc+1)	; check beat counter (scaled by tempo)
		sub	1
		jr	c,.nobeats
		ld	(sbeatAcc+1),a	; 1/24 beat passed.
		set	1,b		; Set BEAT (10b) flag
		call	dac_me		; painful desync here, play 3 WAV bytes
		call	dac_me
		call	dac_me
.nobeats:
		ld	a,b
		or	a
		jr	z,.neither
		call	dac_me
		ld	(currTickBits),a; Save BEAT/TICK bits
; 		call	doenvelope	; TODO: doing this until channels are fully working
		call	check_tick
		call	vtimer		; Voice timers for auto-inserting
		call	check_tick
		call	updseq		; Update track data
		call	check_tick
.neither:
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
		dw .cmnd_trkplay	; $00
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
; $01 - change current wave pitch
; --------------------------------------------------------

.cmnd_trkplay:
		ld	iy,trkBuff
		call	get_cmdbyte		; Pattern data
		ld	(iy+trk_romPatt),a
		call	get_cmdbyte
		ld	(iy+(trk_romPatt+1)),a		
		call	get_cmdbyte
		ld	(iy+(trk_romPatt+2)),a
		call	get_cmdbyte		; Block data
		ld	(iy+trk_romBlk),a
		call	get_cmdbyte
		ld	(iy+(trk_romBlk+1)),a		
		call	get_cmdbyte
		ld	(iy+(trk_romBlk+2)),a
		ld	a,0C0h			; Enable + REFILL flags
		ld	(iy+trk_status),a
		jp	.next_cmd
		
; --------------------------------------------------------
; $21 - change current wave pitch
; --------------------------------------------------------

.cmnd_wav_set:
		ld	iy,wave_Start
		call	get_cmdbyte		; Start address
		ld	(iy),a
		inc	iy
		call	get_cmdbyte
		ld	(iy),a
		inc	iy
		call	get_cmdbyte
		ld	(iy),a
		inc	iy
		call	get_cmdbyte		; Length
		ld	(iy),a
		inc	iy
		call	get_cmdbyte
		ld	(iy),a
		inc	iy
		call	get_cmdbyte
		ld	(iy),a
		inc	iy
		call	get_cmdbyte		; Loop point
		ld	(iy),a
		inc	iy
		call	get_cmdbyte
		ld	(iy),a
		inc	iy
		call	get_cmdbyte
		ld	(iy),a
		inc	iy
		call	get_cmdbyte		; Pitch
		ld	(iy),a
		inc	iy
		call	get_cmdbyte
		ld	(iy),a
		inc	iy
		call	get_cmdbyte		; Flags
		ld	(iy),a
		inc	iy
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
		call	dac_off
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

; --------------------------------------------------------
; Voice timers
; --------------------------------------------------------

vtimer
		ret
; 		call	dac_me
; 		ld	de,7			; de - channel voice size
; 		ld	a,(currTickBits)
; 		ld	b,a			; B <- tbase flags
; 		ld	h,0			; indicates FM voices
; 		ld	ix,FMVTBL
; 		call	.vtimerloop
; 		call	dac_me
; 		inc	h			; indicates PSG voices
; 		ld	ix,PSGVTBL
; 		call	.vtimerloop
; 		ld	ix,PSGVTBLNG
; 		call	.vtimerloop
; 		call	dac_me
; ; 		inc	h			; extra channels
; ; 		jp	.vtimerloop
; 		ret
; 
; .vtimerloop0:
; 		add	ix,de			; Next channel to check
; .vtimerloop:
; 		ld	a,(ix)
; 		cp	-1			; If -1, finish checking
; 		ret	z
; 		call	dac_me
; 		bit	3,a			; sfx tempo driven?
; 		jr	nz,.vtimersfx
; 		bit	1,b			; no - music beat flag set?
; 		jr	z,.vtimerloop0
; 		jr	.vtimerdoit
; .vtimersfx
; 		bit	0,b			; Tick?
; 		jr	z,.vtimerloop0
; .vtimerdoit
; 		bit	6,a			; if in release
; 		jr	Z,.vtimerloop2
; 		dec	(ix+6)			;   decrement release timer
; 		jr	nz,.vtimerloop0		;   not at zero, loop
; 		res	6,a			;   turn off release flag
; 		ld	(ix+0),A
; 		jr	.vtimerloop0
; 
; .vtimerloop2
; 		bit	4,a
; 		jr	z,.vtimerloop0
; 		and	7			; yes - save voice # in C
; 		ld	c,a
; 		inc	(ix+4)			; inc lsb of timer
; 		jr	nz,.vtimerloop0
; 		inc	(ix+5)			; if zero (carry), inc msb
; 		jr	nz,.vtimerloop0
; 		res	4,(ix+0)		; timed out - clear self timer bit
; 		res	3,(ix+0)		;   and clear sfx bit
; 		ld	a,(ix+0)		; A <- note flags
; 		and	2Fh			; mask lock and voice number
; 		cp	06h|20h			; is it voice 6 (must be FM) and locked?
; 		jr	Z,.vtnoteoffdig		;   yes - its a digital noteoff
; 		set	6,(ix+0)		;   no - set release bit
; 		set	7,(ix+0)		;        set free bit
; .vtnoteoff:					; note off...
; 		bit	0,h			; voice type?
; 		jr	Z,.vtnoteofffm
; 		push	de
; 		ld	e,c			; psg - DE <- psg voice num
; 		ld      iy,psgcom		; load psg register table
; 		add	iy,de			; point to correct register
; 		pop	de
; 		set	1,(iy+0)		; set key off command
; 		jr	.vtimerloop0
; .vtnoteofffm
; 		ld	iy,4000H        	; load fm register address
; 		ld	d,28h
; 		ld	e,c
; 		call	SndDrv_FmSet_1
; 		jr	.vtimerloop0
; .vtnoteoffdig:
; 		call	dac_off
; 		jp	.vtimerloop0

; --------------------------------------------------------
; Read track data
; --------------------------------------------------------

currTrkBlkHd	ds 2
currTrkData	ds 2
currDynChn	ds 2

updseq:
		call	dac_me
		ld	iy,trkBuff
		ld	hl,blkHeadC
		ld	de,trkDataC
		ld	(currTrkBlkHd),hl
		ld	(currTrkData),de
		ld	b,MAX_TRKS
.next:
		push	bc
		call	.read_track
		call	dac_me
		pop	bc

; 		ld	de,40h			; Go to next Block and Head lists
; 		ld	hl,(currTrkBlock)
; 		add	hl,de
; 		ld	(currTrkBlock),hl
; 		ld	hl,(currTrkHead)
; 		add	hl,de
; 		ld	(currTrkHead),hl
; 		ld	de,100h			; And next track data FIFO
; 		pop	bc
; 		djnz	.next
		ret

; ----------------------------------------
; Read current track
; ----------------------------------------

; TICK or BEAT passed, read new data
.read_track:
		call	dac_me
; 		ld	a,(currTickBits)
; 		bit	1,a
; 		ret	z
		ld	a,(currTickBits)	; Tick passed?
		bit	0,a
		ret	z
		ld	a,(iy+trk_status)	; Read track status
		bit	7,a			; Active?
		ret	z
		bit	6,a			; Restart?
		call	nz,.refill_all

	; Start reading track
		call	dac_me
		ld	c,(iy+trk_Rows)		; Check if this pattern finished
		ld	b,(iy+(trk_Rows+1))
		ld	a,c
		or	b
		jp	z,.next_track
		call	dac_me
		ld	l,(iy+trk_Read)
		ld	h,(iy+((trk_Read+1)))
		ld	a,(iy+trk_Halfway)	; Check if we got halfway
		xor	h
		and	80h
		call	nz,.refill		; Refill new half and keep going
		call	dac_me
		ld	de,0

; --------------------------------
		ld	a,(hl)			; Check if timer or note
		or	a			; If 00h-7Fh: timer
		jp	m,.is_note
		ld	a,(hl)			; Decrease this timer
		call	dac_me
		dec	a
		ld	(hl),a
		or	a
		ret	nz
		jp	.next_note
.is_note:
		ld	c,a
		and	00111111b
		bit	6,c			; New note-type?
		jp	z,.old_type
		inc 	hl
.old_type:
		add	a,a
		add	a,a
		add	a,a
		add	a,a
		ld	e,a
		ld	ix,(currDynChn)
		add	ix,de

; --------------------------------
; Exit
; --------------------------------

.next_note:
		inc 	l
		dec	bc			; Decrase this row
		ld	(iy+trk_Rows),c		; Update numof rows
		ld	(iy+(trk_Rows+1)),b
		ld	(iy+trk_Read),l		; Update read location
		ld	(iy+((trk_Read+1))),h
		ret

; ----------------------------------------
; Got halfway, recieve data from ROM
; to fill the other half
; ----------------------------------------

.refill:
		jr	$

; ----------------------------------------
; Got in halfway, recieve data
; from ROM to the other half
; ----------------------------------------

.next_track:
		ld	(iy+trk_Read),l		; Save
		ld	(iy+((trk_Read+1))),h
		jr	$

; ----------------------------------------
; First time: refill
; ----------------------------------------

.refill_all:
		res	6,a			; Reset FILL flag
		ld	(iy+trk_status),a
		ld	de,(currTrkData)	; Set new Read point to this track
		ld	(iy+trk_Read),e
		ld	(iy+((trk_Read+1))),d
		call	dac_fill		
		call	dac_me
		
	; RECIEVE DATA FROM ROM:
		ld	l,(iy+trk_romBlk)	; Recieve 40h of block data
		ld	h,(iy+(trk_romBlk+1))
		ld	a,(iy+(trk_romBlk+2))
		ld	de,(currTrkBlkHd)
		ld	bc,80h
		push	de
		call	transferRom
		call	dac_fill		
		call	dac_me
		pop	de
		ld	a,e
		add	a,80h
		ld	e,a
		ld	l,(iy+trk_romPatt)	; Recieve 40h of block data
		ld	h,(iy+(trk_romPatt+1))
		ld	a,(iy+(trk_romPatt+2))
		ld	bc,80h
		call	transferRom
		
	
		call	dac_me			; Read the first pattern for filling
		ld	hl,(currTrkBlkHd)	; Block section
		ld	de,0
		add	hl,de
		ld	a,(hl)			; a - block
		ld	hl,(currTrkBlkHd)	; Header section
		ld	de,80h
		add	hl,de
		add	a,a
		add	a,a
		ld	e,a			; block * 4
		add	hl,de

		call	dac_me
		ld	c,(hl)
		inc	hl
		ld	b,(hl)			; bc - numof Rows
		inc	hl
		ld	e,(hl)
		inc	hl
		ld	d,(hl)			; de - pointer (base+increment by this)
		ld	(iy+trk_Rows),c		; Save this number of rows
		ld	(iy+(trk_Rows+1)),b

		ld	l,(iy+trk_romPatt)	; hl - Low and Mid pointer of ROM patt data
		ld	h,(iy+(trk_romPatt+1))
		ld	a,(iy+(trk_romPatt+2))
		add	hl,de			; increment to get new pointer
		adc	a,0			; and highest byte too.
		call	dac_me
		call	dac_fill
		ld	de,(currTrkData)	; Fill this track's note-data
		ld	bc,080h			; first half
		push	af
		push 	bc
		push	de
		push	hl
		call	transferRom
		call	dac_me
		call	dac_fill
		pop	hl			; second half
		ld	de,80h
		add	hl,de
		pop	de
		pop	bc
		ld	a,e
		add	a,80h
		ld	e,a
		pop	af
		jr	transferRom

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
		and	7Fh			; limit to 64
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
; transferRom
; 
; Transfer bytes from ROM to Z80, this also tells
; to 68k that we are reading fom ROM
; 
; Input:
; a  - Source ROM address $xx0000
; bc - Byte count (size 0 NOT allowed, MAX: 0FFh)
; hl - Source ROM address $00xxxx
; de - Destination address
; 
; Uses:
; b, ix
; 
; Notes:
; call dac_fill first if transfering anything other than
; WAV sample data, just to be safe
; --------------------------------------------------------

transferRom:
		call	dac_me
		push	ix
		ld	ix,commZRomBlk
		ld	(x68ksrclsb),hl
		res	7,h
		ld	b,0
		dec	bc
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
		call	dac_me
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
		call	dac_me
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
; NOTE: This MIGHT cause the DAC to ran out of sample data
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

; --------------------------------------------------------
; bruteforce DAC ON/OFF playback
; --------------------------------------------------------

dac_on:
		ld	a,2Bh
		ld	(Zym_ctrl_1),a
		ld	a,80h
		ld	(Zym_data_1),a
		ld 	a,zopcExx
		ld	(dac_me),a
		ld 	a,zopcPushAf
		ld	(dac_fill),a
		ret
dac_off:
		ld	a,2Bh
		ld	(Zym_ctrl_1),a
		ld	a,00h
		ld	(Zym_data_1),a
		ld 	a,zopcRet
		ld	(dac_me),a
		ld 	a,zopcRet
		ld	(dac_fill),a
		ret

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
		bit	2,c			; bit 2 - stop sound
		jr	z,.ckof
		ld	(iy+LEV),-1		; reset level
		ld	(iy+FLG),1		; and update
		ld	(iy+MODE),0		; envelope off
		ld	a,1			; PSG Channel 3?
		cp	e
		jr	nz,.ckof
		res	5,(ix)			; Unlock PSG3
.ckof:
		bit	1,c			; bit 1 - key off
		jr      z,.ckon
		ld	a,(iy+MODE)		; envelope mode 0?
		cp	0
		jr	z,.ckon
		ld	(iy+FLG),1		; psg update flag
		ld	(iy+MODE),4		; set envelope mode 4
.ckon:
		bit	0,c			; bit 0 - key on
		jr	z,.envproc
		ld	(iy+LEV),-1		; reset level
		ld	a,(iy+DTL)		; load frequency LSB or NOISE data
		or	d			; OR with current channel
		ld	(hl),a			; write it
		ld	a,1			; NOISE channel?
		cp	e
		jr	z,.nskip		; then don't write next byte
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
		call	dac_off
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
		call	dac_on
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
		and	01b
		or	a
		jp	nz,.FDF72
		
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
		call	dac_off
		ld	HL,FMVTBLCH6
		ld	(HL),0C6H		; mark voice free, unlocked, and releasing
		inc	HL
		inc	HL
		inc	HL
		inc	HL
		ld	(HL),0			; clear any pending release timer value
		inc	HL
		ld	(HL),0
		
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

wavFreq_Pwm:	dw 100h		; C-0
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
; FmIns_Fm3_OpenHat:
; 		binclude "data/sound/instr/fm/fm3_openhat.gsx",2478h,28h
; FmIns_Fm3_ClosedHat:
; 		binclude "data/sound/instr/fm/fm3_closedhat.gsx",2478h,28h
; FmIns_DrumKick:
; 		binclude "data/sound/instr/fm/drum_kick.gsx",2478h,20h
; FmIns_DrumSnare:
; 		binclude "data/sound/instr/fm/drum_snare.gsx",2478h,20h
; FmIns_DrumCloseHat:
; 		binclude "data/sound/instr/fm/drum_closehat.gsx",2478h,20h
; FmIns_Piano_m1:
; 		binclude "data/sound/instr/fm/piano_m1.gsx",2478h,20h
; FmIns_Bass_gum:
; 		binclude "data/sound/instr/fm/bass_gum.gsx",2478h,20h
; FmIns_Bass_calm:
; 		binclude "data/sound/instr/fm/bass_calm.gsx",2478h,20h
; FmIns_Bass_heavy:
; 		binclude "data/sound/instr/fm/bass_heavy.gsx",2478h,20h
; FmIns_Bass_ambient:
; 		binclude "data/sound/instr/fm/bass_ambient.gsx",2478h,20h
; FmIns_Brass_gummy:
; 		binclude "data/sound/instr/fm/brass_gummy.gsx",2478h,20h
; FmIns_Flaute_1:
; 		binclude "data/sound/instr/fm/flaute_1.gsx",2478h,20h
; FmIns_Bass_2:
; 		binclude "data/sound/instr/fm/bass_2.gsx",2478h,20h
; FmIns_Bass_3:
; 		binclude "data/sound/instr/fm/bass_3.gsx",2478h,20h
; FmIns_Bass_5:
; 		binclude "data/sound/instr/fm/bass_5.gsx",2478h,20h
; FmIns_Bass_synth:
; 		binclude "data/sound/instr/fm/bass_synth_1.gsx",2478h,20h
; FmIns_Guitar_1:
; 		binclude "data/sound/instr/fm/guitar_1.gsx",2478h,20h
; FmIns_Horn_1:
; 		binclude "data/sound/instr/fm/horn_1.gsx",2478h,20h
; FmIns_Organ_M1:
; 		binclude "data/sound/instr/fm/organ_m1.gsx",2478h,20h
; FmIns_Bass_Beach:
; 		binclude "data/sound/instr/fm/bass_beach.gsx",2478h,20h
; FmIns_Bass_Beach_2:
; 		binclude "data/sound/instr/fm/bass_beach_2.gsx",2478h,20h
; FmIns_Brass_Cave:
; 		binclude "data/sound/instr/fm/brass_cave.gsx",2478h,20h
; FmIns_Piano_Small:
; 		binclude "data/sound/instr/fm/piano_small.gsx",2478h,20h
; FmIns_Trumpet_2:
; 		binclude "data/sound/instr/fm/trumpet_2.gsx",2478h,20h
; FmIns_Bell_Glass:
; 		binclude "data/sound/instr/fm/bell_glass.gsx",2478h,20h
; FmIns_Marimba_1:
; 		binclude "data/sound/instr/fm/marimba_1.gsx",2478h,20h
; FmIns_Ambient_dark:
; 		binclude "data/sound/instr/fm/ambient_dark.gsx",2478h,20h
; FmIns_Ambient_spook:
; 		binclude "data/sound/instr/fm/ambient_spook.gsx",2478h,20h
; FmIns_Ding_toy:
; 		binclude "data/sound/instr/fm/ding_toy.gsx",2478h,20h

; ====================================================================
; ----------------------------------------------------------------
; Z80 RAM
; ----------------------------------------------------------------

; --------------------------------------------------------
; Internal
; --------------------------------------------------------

		align 800h
dWaveBuff	ds 100h			; WAVE data buffer: updated every 80h bytes
trkDataC	ds 100h*MAX_TRKS	; Track data cache: 100h bytes each
blkHeadC	ds 100h*MAX_TRKS	; Track blocks and heads: 40h each
trkBuff		ds 20h*MAX_TRKS		; Track buffer
chnBuff		ds 20h*MAX_CHNLS	; Internal dynamic channels


commZfifo	ds 80h			; Buffer for command requests from 68k
; CCB		ds 512			; TODO
; CH0BUF		ds 256		; TODO channel cache - 256 bytes
tickFlag	dw 0			; Tick flag from VBlank, Read as (tickFlag+1) for reading/reseting
tickCnt		db 0			; Tick counter (PUT THIS TAG AFTER tickFlag)
sbeatPtck	dw 204			; Sub beats per tick (8frac), default is 120bpm
sbeatAcc	dw 0			; Accumulates ^^ each tick to track sub beats
currTickBits	db 0			; Current Tick/Tempo bitflags (000000BTb B-beat, T-tick)
dDacPntr	db 0,0,0		; WAVE play current ROM position
dDacCntr	db 0,0,0		; WAVE play length counter
dDacFifoMid	db 0			; WAVE play halfway refill flag (00h/80h)
x68ksrclsb	db 0			; transferRom temporal LSB
x68ksrcmid	db 0			; transferRom temporal MID
commZRead	db 0			; read pointer (here)
commZWrite	db 0			; cmd fifo wptr (from 68k)
commZRomBlk	db 0			; 68k ROM block flag
commZRomRd	db 0			; Z80 is reading ROM bit

; dynamic chip allocation
; *  FMVTBL - contains (6) 7-byte entires, one per voice:
; *    byte 0: FRLxxVVV	flag byte, where F=free, R=release phase, L=locked, VVV=voice num
; *                       VVV is numbered (0,1,2,4,5,6) for writing directly to key on/off reg
; *    byte 1: priority	only valid for in-use (F=0) voices
; *    byte 2: notenum	    "
; *    byte 3: channel	    "
; *    byte 4: lsb of duration timer (for sequenced notes)
; *    byte 5: msb of duration timer
; *    byte 6: release timer
		
psgcom		db 00h,00h,00h,00h	;  0 command 1 = key on, 2 = key off, 4 = stop snd
psglev		db  -1, -1, -1, -1	;  4 output level attenuation (%llll.0000, -1 = silent) 
psgatk		db 00h,00h,00h,00h	;  8 attack rate
psgdec		db 00h,00h,00h,00h	; 12 decay rate
psgslv		db 00h,00h,00h,00h	; 16 sustain level attenuation
psgrrt		db 00h,00h,00h,00h	; 20 release rate
psgenv		db 00h,00h,00h,00h	; 24 envelope mode 0 = off, 1 = attack, 2 = decay, 3 = sustain, 4
psgdtl		db 00h,00h,00h,00h	; 28 tone bottom 4 bits, noise bits
psgdth		db 00h,00h,00h,00h	; 32 tone upper 6 bits
psgalv		db 00h,00h,00h,00h	; 36 attack level attenuation
whdflg		db 00h,00h,00h,00h	; 40 flags to indicate hardware should be updated
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
wave_Pitch	dw 100h			; 01.00h
wav_Flags	db 100b			; WAVE playback flags (%10x: 1 loop / 0 no loop)

; ====================================================================

		cpu 68000
		padding off
		phase Z80_CODE+*
Z80_CODE_END:
		align 2
