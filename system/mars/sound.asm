; ====================================================================
; ----------------------------------------------------------------
; MARS Sound
; ----------------------------------------------------------------

MAX_PWMCHNL	equ	8

; 32X sound channel
		struct 0
mchnsnd_enbl	ds.l 1
mchnsnd_read	ds.l 1		; 0 - off
mchnsnd_bank	ds.l 1		; CS0-3 OR value
mchnsnd_start	ds.l 1
mchnsnd_end	ds.l 1
mchnsnd_loop	ds.l 1
mchnsnd_pitch	ds.l 1
mchnsnd_flags	ds.l 1
mchnsnd_vol	ds.l 1
sizeof_sndchn	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; Mars PWM playback (Runs on PWM interrupt)
; 
; READ/START/END/LOOP points are floating values (xxxxxx.00)
; 
; r0-r9 only
; ----------------------------------------------------------------

; NUMCHANNELS	equ	4
; PWMSIZE		equ	2	; number of elemts in the PWM structure
; 
; PWMADDRESS	equ	4
; 
; process_pwm:
; 
; 	mov.l	#$20004038,r2
; 
; @loop
; 	mov.l	#pwmstructs,r3
; 	mov	#NUMCHANNELS,r4
; 	mov	#0,r5
; 
; @channelloop:
; 	mov.l	@r3,r0				;is channel on?
; 	cmp/eq	#0,r0
; 	bf	@on
; 
; 	mov.l	#$7f,r1				;if channel off, use $7f (flat)
; 	bra	@skip
; 	nop
; @on:
; 	add.l	#-1,r0
; 	mov.l	r0,@r3
; 
; 	mov.l	@(PWMADDRESS,r3),r0		;get the next pcm byte
; 	mov.l	r0,r1
; 	add.l	#1,r0
; 	mov.l	r0,@(PWMADDRESS,r3)
; 	shlr	r1
; 	mov.b	@r1,r1
; 	extu.b	r1,r1
; 
; @skip:
; 	add	#8,r3
; 
; 	add.l	#1,r1   			;make sure it's not 0
; 	add	r1,r5
; 
; 	dt	r4
; 	bf	@channelloop
; 
; 	mov.w	r5,@r2				;store into mono width
; 
; 	mov.b	@r2,r0				;is pwm fifo full?
; 	tst	#$80,r0
; 	bt	@loop
; 
; 	rts
; 	nop
; 
; 	lits

MarsSound_ReadPwm:
		mov.l	r2,@-r15
		mov.l	r3,@-r15
		mov.l	r4,@-r15
		mov.l	r5,@-r15
		mov.l	r6,@-r15
		mov.l	r7,@-r15
		mov.l	r8,@-r15
		mov.l	r9,@-r15
.retry:
		mov 	#1,r3			; LEFT start
		mov 	#1,r4			; RIGHT start
		mov	#MarsSnd_PwmChnls,r8
		mov 	#MAX_PWMCHNL,r9
		
; ------------------------------------------------
; Read wave data
; ------------------------------------------------

.nxtchn:
		mov 	@(mchnsnd_enbl,r8),r0
		cmp/eq	#0,r0
		bf	.chnon
		mov	#$7F,r0
		add	r0,r3
		bra	.chnoff
		add	r0,r4

; Active channel
.chnon:
		mov 	@(mchnsnd_read,r8),r1
		mov 	@(mchnsnd_end,r8),r0
		cmp/ge	r0,r1
		bf	.read
		mov 	@(mchnsnd_loop,r8),r0
		cmp/eq	#-1,r0
		bf	.noend
		mov 	#0,r0
		mov 	r0,@(mchnsnd_enbl,r8)
		mov 	@(mchnsnd_start,r8),r1
		bra	.keep
		nop
.noend:
		mov 	@(mchnsnd_start,r8),r1
		bra	.keep
		nop
.read:
		mov 	@(mchnsnd_flags,r8),r0
		mov	#$00FFFFFF,r7
		mov 	r1,r2
		shlr8	r2
		tst	#%100,r0
		bt	.mono_a
		add	#-1,r7
.mono_a
		and	r7,r2
		mov 	@(mchnsnd_bank,r8),r7
		or	r7,r2
		mov 	@(mchnsnd_pitch,r8),r7
		mov.b	@r2+,r5
		mov	r5,r6
		tst	#%100,r0
		bt	.mono
		mov.b	@r2+,r6
		shll	r7			; increment * 2
.mono:
		add	r7,r1
		extu.b	r5,r5
		extu.b	r6,r6
		add	#1,r5
		add	#1,r6
		; volume goes here
		
.updwav:
		tst	#%10,r0
		bt	.nor
		add	r5,r3
.nor:
		tst	#%01,r0
		bt	.keep
		add	r6,r4
.keep:
		mov	#$7FF,r7
		and	r7,r3
		and	r7,r4
		mov 	r1,@(mchnsnd_read,r8)
.chnoff:


		add	#sizeof_sndchn,r8
		dt	r9
		bf	.nxtchn

; ------------------------------------------------
; Play wave
; 
; r3 - left wave
; r4 - right wave
; ------------------------------------------------

		mov	#_sysreg+monowidth,r5
		mov	#_sysreg+lchwidth,r1
		mov	#_sysreg+rchwidth,r2
 		mov.w	r3,@r1
 		mov.w	r4,@r2
		mov.b	@r5,r0
 		tst	#$80,r0			; PWM FIFO full?
 		bt	.retry			; loop until it fills
		mov	#_sysreg+comm4,r5
 		mov.w	r3,@r5
 		mov	r4,r0
 		mov.w	r0,@(2,r5)
.full:

		mov.l	@r15+,r9
		mov.l	@r15+,r8
		mov.l	@r15+,r7
		mov.l	@r15+,r6
		mov.l	@r15+,r5
		mov.l	@r15+,r4
		mov.l	@r15+,r3
		mov.l	@r15+,r2
		rts
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Mars PWM control (Runs on VBlank)
; ----------------------------------------------------------------

MarsSound_Run:
		sts	pr,@-r15

		lds	@r15+,pr
		rts
		nop
		align 4

; ====================================================================
; ----------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; Init Sound PWM
; 
; Frequency values:
; 23011361 NTSC
; 22801467 PAL
; 
; NOTE: cycle causes a CLICK to sound
; --------------------------------------------------------

MarsSound_Init:
		sts	pr,@-r15
		stc	gbr,@-r15
		mov	#_sysreg,r0
		ldc	r0,gbr
		mov	#((((23011361<<1)/22050+1)>>1)+1),r0	; 22050 best
		mov.w	r0,@(cycle,gbr)
		mov	#$0305,r0
		mov.w	r0,@(timerctl,gbr)
		mov	#0,r0
		mov.w	r0,@(monowidth,gbr)
		mov.w	r0,@(monowidth,gbr)
		mov.w	r0,@(monowidth,gbr)
		
		mov	#0,r0
		mov	#MarsSnd_PwmChnls,r1
		mov	#MAX_PWMCHNL,r2
		mov	#sizeof_sndchn,r3
.clr_enbl:
		mov	r0,@(mchnsnd_enbl,r1)
		dt	r2
		bf/s	.clr_enbl
		add	r3,r1
		ldc	@r15+,gbr
		lds	@r15+,pr
		rts
		nop
		align 4

; --------------------------------------------------------
; MarsSound_SetPwm
; 
; Set new sound data to a single channel
; 
; Input:
; r1 | Channel
; r2 | Start address
; r3 | End address
; r4 | Loop address (-1, dont loop)
; r5 | Pitch ($xxxxxx.xx)
; r6 | Volume
; r7 | Flags (Currently: %xxxxxxLR)
; 
; Uses:
; r0,r8-r9
; --------------------------------------------------------

MarsSound_SetPwm:
		stc	sr,r9
		mov	#$F0,r0
		ldc	r0,sr
		mov	#MarsSnd_PwmChnls,r8
		mov 	#sizeof_sndchn,r0
		mulu	r1,r0
		sts	macl,r0
		add 	r0,r8
		mov 	#0,r0
		mov 	r0,@(mchnsnd_enbl,r8)
		mov 	r0,@(mchnsnd_read,r8)
		mov 	r0,@(mchnsnd_bank,r8)
		
		mov 	r5,@(mchnsnd_pitch,r8)
		mov 	r6,@(mchnsnd_vol,r8)		
		mov 	r7,@(mchnsnd_flags,r8)
		mov 	r2,r0				; Set MSB
		mov 	#$FF000000,r7
		and 	r7,r0
		mov 	r0,@(mchnsnd_bank,r8)
		mov 	r4,r0				; Set POINTS
		cmp/eq	#-1,r0
		bt	.endmrk
		shll8	r0
.endmrk:
		mov	r0,@(mchnsnd_loop,r8)
		mov 	r3,r0
		shll8	r0
		mov	r0,@(mchnsnd_end,r8)
		mov 	r2,r0
		shll8	r0
		mov 	r0,@(mchnsnd_start,r8)	
		mov 	r0,@(mchnsnd_read,r8)
		mov 	#1,r0
		mov 	r0,@(mchnsnd_enbl,r8)
 		ldc	r9,sr
		rts
		nop
		align 4

; --------------------------------------------------------
; MarsSound_MulPwmPitch
; 
; Set pitch data to 8 consecutive sound channels
; starting from specific slot
; 
; Input:
; r1 | Channel pitch slot 0
; r2 | Channel pitch slot 1
; r3 | Channel pitch slot 2
; r4 | Channel pitch slot 3
; r5 | Channel pitch slot 4
; r6 | Channel pitch slot 5
; r7 | Channel pitch slot 6
; r8 | Channel pitch slot 6
; r9 | Start from slot id
; 
; Uses:
; r0,r10-r12
; --------------------------------------------------------

MarsSound_MulPwmPitch:
		stc	sr,r12
		mov	#$F0,r0
		ldc	r0,sr
		mov	#MarsSnd_PwmChnls,r11
		mov 	#sizeof_sndchn,r0
		mulu	r9,r0
		sts	macl,r0
		add 	r0,r11
		mov	#sizeof_sndchn,r10
		mov	@(mchnsnd_enbl,r11),r0
		cmp/pl	r0
		bf	.off_1
		mov	r1,@(mchnsnd_pitch,r11)
.off_1:
		add	r10,r11
		mov	@(mchnsnd_enbl,r11),r0
		cmp/pl	r0
		bf	.off_2
		mov	r2,@(mchnsnd_pitch,r11)
		add	r10,r11
.off_2:	
		mov	@(mchnsnd_enbl,r11),r0
		cmp/pl	r0
		bf	.off_3
		mov	r3,@(mchnsnd_pitch,r11)
		add	r10,r11
.off_3:	
		mov	@(mchnsnd_enbl,r11),r0
		cmp/pl	r0
		bf	.off_4
		mov	r4,@(mchnsnd_pitch,r11)
		add	r10,r11
.off_4:	
		mov	@(mchnsnd_enbl,r11),r0
		cmp/pl	r0
		bf	.off_5
		mov	r5,@(mchnsnd_pitch,r11)
		add	r10,r11
.off_5:	
		mov	@(mchnsnd_enbl,r11),r0
		cmp/pl	r0
		bf	.off_6
		mov	r6,@(mchnsnd_pitch,r11)
		add	r10,r11
.off_6:
		mov	@(mchnsnd_enbl,r11),r0
		cmp/pl	r0
		bf	.off_7
		mov	r7,@(mchnsnd_pitch,r11)
		add	r10,r11
.off_7:
		mov	@(mchnsnd_enbl,r11),r0
		cmp/pl	r0
		bf	.off_8
		mov	r8,@(mchnsnd_pitch,r11)
.off_8:
 		ldc	r12,sr
		rts
		nop
		align 4

; ====================================================================

		ltorg			; Save literals
