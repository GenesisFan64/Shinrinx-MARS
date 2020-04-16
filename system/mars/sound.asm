; ====================================================================
; ----------------------------------------------------------------
; MARS Sound
; ----------------------------------------------------------------

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

; --------------------------------------------------------
; Init Sound
; 
; Uses:
; a0-a2,d0-d1
; 
; 23011361 NTSC
; 22801467 PAL
; --------------------------------------------------------

MarsSound_Init:
		sts	pr,@-r15

		mov	#((((23011361<<1)/32000+1)>>1)+1),r0	; 32000 works but the CPU must be calm
		mov.w	r0,@(cycle,gbr)
		mov	#$0105,r0
		mov.w	r0,@(timerctl,gbr)
		mov	#1,r0
		mov.w	r0,@(monowidth,gbr)
		mov.w	r0,@(monowidth,gbr)
		mov.w	r0,@(monowidth,gbr)

		lds	@r15+,pr
		rts
		nop
		align 4

; --------------------------------------------------------
; MARS sound player (VBlank routine)
; --------------------------------------------------------

MarsSound_Run:
		sts	pr,@-r15

		lds	@r15+,pr
		rts
		nop
		align 4

; ====================================================================
; ----------------------------------------------------------------
; Mars PWM driver (Runs on PWM interrupt)
; 
; READ/START/END/LOOP points are floating values (xxxxxx.00)
; 
; r0-r7 only
; ----------------------------------------------------------------

MarsSound_PWM:
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
		shll 	r0
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
; ------------------------------------------------

.full:
  		mov.w	@(monowidth,gbr),r0
  		shlr8	r0
 		tst	#$80,r0
 		bf	.full
 		
 		mov	r3,r0
 		mov.w	r0,@(lchwidth,gbr)
 		mov	r4,r0
 		mov.w	r0,@(rchwidth,gbr)
		rts
		nop
		align 4

; ====================================================================
; ----------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------

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
; --------------------------------------------------------

MarsSound_SetChannel:
		mov	#MarsSnd_Pwm,r8
		mov 	#sizeof_sndchn,r0
		mulu	r1,r0
		sts	macl,r0
		add 	r0,r8

		mov 	r5,@(mchnsnd_pitch,r8)
		mov 	r6,@(mchnsnd_vol,r8)		
		mov 	r7,@(mchnsnd_flags,r8)
		
	; Set BANK
		mov 	r2,r0
		mov 	#$FF000000,r7
		and 	r7,r0
		mov 	r0,@(mchnsnd_bank,r8)

	; Set POINTS
		mov 	r4,r0
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
		rts
		nop
		align 4

; --------------------------------------------------------
; Sound_SetPitch
; 
; Set pitch number
; 
; Input:
; d0 | WORD - Pitch data
; --------------------------------------------------------

MarsSound_SetPitch:
		rts
		nop
		align 4

; ====================================================================

		ltorg			; Save literals
