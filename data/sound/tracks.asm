; ================================================================
; ------------------------------------------------------------
; DATA SECTION
; 
; SOUND
; ------------------------------------------------------------

gemaInsPsg	macro pitch,psgins
		dc.b 0,pitch
		dc.b psgins&$FF,((psgins>>8)&$FF)
		dc.b 0,0
		dc.b 0,0
		endm

gemaInsPsgN	macro pitch,psgins,type
		dc.b 1,pitch
		dc.b psgins&$FF,((psgins>>8)&$FF)
		dc.b type,0
		dc.b 0,0
		endm

gemaInsFm	macro pitch,fmins
		dc.b 2,pitch
		dc.b fmins&$FF,((fmins>>8)&$FF)
		dc.b 0,0
		dc.b 0,0
		endm

gemaInsFm3	macro pitch,fmins,freq1,freq2,freq3
		dc.b 3,pitch
		dc.b fmins&$FF,((fmins>>8)&$FF)
		dc.b 0,0
		dc.b 0,0		
		endm
		
; gemaInsDac	macro pitch,start,len,loop,flags
; 		dc.b 4,pitch
; 		dc.b start&$FF,((start>>8)&$FF),((start>>16)&$FF)
; 		dc.b len&$FF,((len>>8)&$FF),((len>>16)&$FF)
; 		dc.b loop&$FF,((loop>>8)&$FF),((loop>>16)&$FF)
; 		dc.b 0,0
; 		endm

gemaInsNull	macro
		dc.b -1,0
		dc.b  0,0
		dc.b  0,0
		dc.b  0,0
		endm

; ------------------------------------------------------------

TEST_BLOCKS	binclude "data/sound/tracks/temple_blk.bin"
TEST_PATTERN	binclude "data/sound/tracks/temple_patt.bin"
TEST_INSTR
		gemaInsPsg  0,PsgIns_01
		gemaInsPsg  0,PsgIns_02
		gemaInsPsgN 0,PsgIns_Snare,%101

TEST_BLOCKS_2	binclude "data/sound/tracks/kraid_blk.bin"
TEST_PATTERN_2	binclude "data/sound/tracks/kraid_patt.bin"
TEST_INSTR_2
		gemaInsPsgN 0,PsgIns_Bass,%011
		gemaInsPsg  0,PsgIns_00

GemaTrk_Yuki_blk:
		binclude "data/sound/tracks/yuki_blk.bin"
GemaTrk_Yuki_patt:
		binclude "data/sound/tracks/yuki_patt.bin"
GemaTrk_Yuki_ins:
		gemaInsNull
		gemaInsFm   0,FmIns_Trumpet_2
		gemaInsFm   0,FmIns_Bass_2
		gemaInsNull
		gemaInsNull
		gemaInsFm   0,FmIns_Piano_Small
		gemaInsPsg  0,PsgIns_00
		gemaInsPsgN 0,PsgIns_Snare,%100
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull

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
