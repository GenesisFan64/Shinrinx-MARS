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
		mov.l	r9,@-r15

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
		bt	.chnoff
		mov 	@(mchnsnd_read,r8),r1

; Check end and loop
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
		mov	#$FF,r7
		and 	r7,r5
		and 	r7,r6
; 		shll	r5
; 		shll	r6
		tst	#%10,r0
		bt	.nor
		add	r5,r3
.nor:
		tst	#%01,r0
		bt	.keep
		add	r6,r4
.keep:
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

		mov	#_sysreg+comm4,r5
		mov	#_sysreg+monowidth,r1
; .full:
; 		mov.b	@r1,r0
;  		tst	#$80,r0
;  		bf	.full
		mov	#_sysreg+lchwidth,r1
		mov	#_sysreg+rchwidth,r2
 		mov.w	r3,@r1
 		mov.w	r4,@r2
 		mov.w	r3,@r5
 		mov	r4,r0
 		mov.w	r0,@(2,r5)
 		
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
; Subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; Init Sound PWM
; 
; Frequency values:
; 23011361 NTSC
; 22801467 PAL
; 
; NOTE: This causes a CLICK on PWM, it's normal
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
		mov	r1,@(mchnsnd_pitch,r11)
		add	r10,r11
		mov	r2,@(mchnsnd_pitch,r11)
		add	r10,r11
		mov	r3,@(mchnsnd_pitch,r11)
		add	r10,r11
		mov	r4,@(mchnsnd_pitch,r11)
		add	r10,r11
		mov	r5,@(mchnsnd_pitch,r11)
		add	r10,r11
		mov	r6,@(mchnsnd_pitch,r11)
		add	r10,r11
		mov	r7,@(mchnsnd_pitch,r11)
		add	r10,r11
		mov	r8,@(mchnsnd_pitch,r11)
 		ldc	r12,sr
		rts
		nop
		align 4

; ====================================================================

		ltorg			; Save literals
