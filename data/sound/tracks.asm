; ================================================================
; ------------------------------------------------------------
; DATA SECTION
; 
; SOUND
; ------------------------------------------------------------

; TEST_BLOCKS	binclude "data/sound/tracks/kraid_blk.bin"
; TEST_PATTERN	binclude "data/sound/tracks/kraid_patt.bin"
; TEST_INSTR
; 		dc.b $01,%011		; Type 1: 
; 		dc.b $00		; Attack level
; 		dc.b $60		; Attack rate
; 		dc.b $10		; Sustain
; 		dc.b $02		; Decay rate
; 		dc.b $02		; Release rate
; 		dc.b $00
; 		dc.b $00,$00		; Type 0, NoiseMode (Type1 only)
; 		dc.b $08		; Attack level
; 		dc.b $40		; Attack rate
; 		dc.b $00		; Sustain
; 		dc.b $00		; Decay rate
; 		dc.b $00		; Release rate
; 		dc.b $00

		
TEST_BLOCKS	binclude "data/sound/tracks/temple_blk.bin"
TEST_PATTERN	binclude "data/sound/tracks/temple_patt.bin"
TEST_INSTR	dc.b $00,$00		; Type 0
		dc.b $40		; Attack level
		dc.b $40		; Attack rate
		dc.b $80		; Sustain
		dc.b $01		; Decay rate
		dc.b $40		; Release rate
		dc.b $00
		dc.b $00,$00
		dc.b $40		; Attack level
		dc.b $60		; Attack rate
		dc.b $80		; Sustain
		dc.b $01		; Decay rate
		dc.b $40		; Release rate
		dc.b $00
		dc.b $01,%101		; Type 1: 
		dc.b $00		; Attack level
		dc.b $C0		; Attack rate
		dc.b $40		; Sustain
		dc.b $20		; Decay rate
		dc.b $40		; Release rate
		dc.b $00
