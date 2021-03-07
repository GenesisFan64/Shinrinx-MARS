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

TEST_BLOCKS_2	binclude "data/sound/tracks/kraid_blk.bin"
TEST_PATTERN_2	binclude "data/sound/tracks/kraid_patt.bin"
TEST_INSTR_2
		dc.b $01,$00		; Type 1: 
		dc.b $00		; Attack level
		dc.b $FF		; Attack rate
		dc.b $20		; Sustain
		dc.b $01		; Decay rate
		dc.b $01		; Release rate
		dc.b %011		; NOISE type
		dc.b $00,$00
		dc.b $30		; Attack level
		dc.b $FF		; Attack rate
		dc.b $00		; Sustain
		dc.b $00		; Decay rate
		dc.b $40		; Release rate
		dc.b $00
		

; ====================================================================
; ----------------------------------------------------------------
; FM Instruments
; ----------------------------------------------------------------

; ----------------------------------------------------
; PSG Instruments
; ----------------------------------------------------

; zinsPsg_00:	db 0,0,0
; 		align 4
		
; ----------------------------------------------------
; FM Instruments
; ----------------------------------------------------

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
