; ================================================================
; ------------------------------------------------------------
; DATA SECTION
; 
; SOUND
; ------------------------------------------------------------

; *** Instrument reference ***
; PSG CHANNEL:
; 	dc.b $00,$00		; Type 0 or 1
; 	dc.b $00		; Pitch up or down
; 	dc.b $40		; Attack level
; 	dc.b $40		; Attack rate
; 	dc.b $80		; Sustain
; 	dc.b $01		; Decay rate
; 	dc.b $40		; Release rate
; 	dc.b $00		; if Type1: Noise mode (%wtt), else: null

		
TEST_BLOCKS	binclude "data/sound/tracks/temple_blk.bin"
TEST_PATTERN	binclude "data/sound/tracks/temple_patt.bin"
TEST_INSTR	dc.b $00,$00		; Type 0
		dc.b $40		; Attack level
		dc.b $40		; Attack rate
		dc.b $80		; Sustain
		dc.b $01		; Decay rate
		dc.b $10		; Release rate
		dc.b $00
		dc.b $00,$00
		dc.b $30		; Attack level
		dc.b $60		; Attack rate
		dc.b $80		; Sustain
		dc.b $04		; Decay rate
		dc.b $04		; Release rate
		dc.b $00
		dc.b $01,$00		; Type 1: 
		dc.b $00		; Attack level
		dc.b $FF		; Attack rate
		dc.b $00		; Sustain
		dc.b $F0		; Decay rate
		dc.b $F0		; Release rate
		dc.b %101		; NOISE type

; TEST_BLOCKS	binclude "data/sound/tracks/kraid_blk.bin"
; TEST_PATTERN	binclude "data/sound/tracks/kraid_patt.bin"
; TEST_INSTR
; 		dc.b $01,$00		; Type 1: 
; 		dc.b $00		; Attack level
; 		dc.b $FF		; Attack rate
; 		dc.b $20		; Sustain
; 		dc.b $01		; Decay rate
; 		dc.b $01		; Release rate
; 		dc.b %011		; NOISE type
; 		dc.b $00,$00
; 		dc.b $30		; Attack level
; 		dc.b $FF		; Attack rate
; 		dc.b $00		; Sustain
; 		dc.b $00		; Decay rate
; 		dc.b $40		; Release rate
; 		dc.b $00
		
