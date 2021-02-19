; ====================================================================
; ----------------------------------------------------------------
; MARS Sound
; ----------------------------------------------------------------

MAX_PWMCHNL	equ	16

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
; Mars PWM playback (Runs on PWM interrupt)
; 
; READ/START/END/LOOP points are floating values (xxxxxx.00)
; 
; r0-r8 only
; ----------------------------------------------------------------

MarsSound_PWM:
		mov.l	r2,@-r15
		mov.l	r3,@-r15
		mov.l	r4,@-r15
		mov.l	r5,@-r15
		mov.l	r6,@-r15
		mov.l	r7,@-r15
		mov.l	r8,@-r15
		mov	#MarsSnd_Pwm,r7
		mov 	#1,r3			; LEFT
		mov 	#1,r4			; RIGHT
		mov 	#8,r5			; numof_chn
		
; ------------------------------------------------
; Read wave data
; ------------------------------------------------

.nxtchn:
		mov 	@(mchnsnd_enbl,r7),r0
		cmp/eq	#0,r0
		bt	.chnoff
		mov 	@(mchnsnd_read,r7),r1
		mov 	r1,r2
		mov 	@(mchnsnd_bank,r7),r0
		shlr8	r2
		or	r0,r2

; Check end and loop
		mov 	@(mchnsnd_end,r7),r0
		cmp/ge	r0,r1
		bf	.read
		mov 	@(mchnsnd_loop,r7),r0
		cmp/eq	#-1,r0
		bf	.noend
		mov 	#0,r0
		mov 	r0,@(mchnsnd_enbl,r7)
		mov 	@(mchnsnd_start,r7),r1
		bra	.keep
		nop
.noend:
		mov 	@(mchnsnd_start,r7),r1
		bra	.keep
		nop
; Read WAV
.read:
		mov.b	@r2,r0
		and 	#$FF,r0
		shll	r0				; manual volume
		mov 	r0,r2
		mov 	@(mchnsnd_flags,r7),r0
		tst	#2,r0
		bt	.nor
		add	r2,r3
.nor:
		tst	#1,r0
		bt	.nol
		add	r2,r4
.nol:
		mov 	@(mchnsnd_pitch,r7),r0
		add	r0,r1
		
; save read
.keep:
		mov 	r1,@(mchnsnd_read,r7)

.chnoff:
		add	#sizeof_sndchn,r7
		dt	r5
		bf	.nxtchn

; ------------------------------------------------
; Play wave
; 
; r3 - left wave
; r4 - right wave
; ------------------------------------------------

		mov	#_sysreg+monowidth,r1
.full:
		mov.b	@r1,r0
 		tst	#$80,r0
 		bf	.full
		mov	#_sysreg+lchwidth,r1
		mov	#_sysreg+rchwidth,r2
 		mov	r3,r0
 		mov.w	r0,@r1
 		mov	r4,r0
 		mov.w	r0,@r2
 		
		mov	#_sysreg+comm4,r1
		mov.w	@r1,r0
		add	#1,r0
		mov.w	r0,@r1

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
; Subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; Init Sound PWM
; 
; Frequency values:
; 23011361 NTSC
; 22801467 PAL
; 
; NOTE: This causes a CLICK on boot, it's normal
; --------------------------------------------------------

MarsSound_Init:
		sts	pr,@-r15
		stc	gbr,@-r15
		mov	#_sysreg,r0
		ldc	r0,gbr
		mov	#((((23011361<<1)/22050+1)>>1)+1),r0	; 22050 best
		mov.w	r0,@(cycle,gbr)
		mov	#$0105,r0
		mov.w	r0,@(timerctl,gbr)
		mov	#1,r0
		mov.w	r0,@(monowidth,gbr)
		mov.w	r0,@(monowidth,gbr)
		mov.w	r0,@(monowidth,gbr)
		ldc	@r15+,gbr
		lds	@r15+,pr
		rts
		nop
		align 4

; --------------------------------------------------------
; MarsSound_SetChannel
; 
; Set sound data to channel
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

MarsSound_SetChannel:
; 		stc	sr,r9
; 		mov	#$F0,r0
; 		ldc	r0,sr
		mov	#MarsSnd_Pwm,r8
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
;  		ldc	r9,sr
		rts
		nop
		align 4

; ====================================================================

		ltorg			; Save literals
