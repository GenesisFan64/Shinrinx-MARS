; ================================================================
; ------------------------------------------------------------
; DATA SECTION
; 
; SOUND
; ------------------------------------------------------------

; TYPES:
;  -1 - ignore
;   0 - FM normal
;   1 - FM special
;   2 - FM sample
; $80 - PSG
; $E0 - PSG noise

; insFM		equ 0
; insFM3		equ 1
; insFM6		equ 2
; insPSG		equ $80
; insPBass0	equ $E0
; insPBass1	equ $E1
; insPBass2	equ $E2
; insPBass3	equ $E3		; Grabs PSG3 frequency
; insPNoise0	equ $E4
; insPNoise1	equ $E5
; insPNoise2	equ $E6
; insPNoise3	equ $E7		; Grabs PSG3 frequency
; 
; instrSlot	macro TYPE,OPT,LABEL
; 	if TYPE=-1
; 		dc.b -1,-1,-1,-1
; 	else
; 		dc.b TYPE,OPT
; 		dc.b LABEL&$FF,((LABEL>>8)&$FF)
; 	endif
; 		endm
; 
; instrSmpl	macro FLAGS,LABEL1,LABEL2,LABEL3
; 		dc.b LABEL1&$FF,LABEL1>>8&$7F|$80,((LABEL1>>15)&$FF)
; 		dc.b LABEL2&$FF,LABEL2>>8&$7F|$80,((LABEL2>>15)&$FF)
; 		dc.b LABEL3&$FF,LABEL3>>8&$7F|$80,((LABEL3>>15)&$FF)
; 		dc.b FLAGS
; 		endm
; 
; ; ----------------------------------------------------
; ; Sound bank for Z80
; ; ----------------------------------------------------
; 		align $8000				; Align to bank
; ZSnd_MusicBank:
; 		phase $8000
; 		
; ; MusicBlk_Sample:
; ; 		binclude "game/sound/music/musictrck_blk.bin"		; BLOCKS data
; ; MusicPat_Sample:
; ; 		binclude "game/sound/music/musictrck_patt.bin"		; PATTERN data
; ; Instruments staring from number 01
; ; MusicIns_Sample:
; ; 		instrSlot      insFM,0,FmIns_Piano_Small		; FM normal: type,pitch,regdata
; ; 		instrSlot     insFM3,0,FmIns_Fm3_OpenHat		; FM special (channel 3): type,pitch,regdata+exfreq
; ; 		instrSlot     insFM3,0,FmIns_Fm3_ClosedHat
; ; 		instrSlot     insFM6,0,.kick				; FM sample (channel 6): type,pitch,custompointer (see below)
; ; 		instrSlot     insFM6,0,.snare
; ; 		instrSlot     insPSG,0,PsgIns_00			; PSG (channels 1-3): type,pitch,envelope data
; ; 		instrSlot insPBass0,0,PsgIns_00				; PSG Noise (channels 1-3): type,pitch,envelope data
; ; 		instrSlot insPBass1,0,PsgIns_00
; ; 		instrSlot insPBass2,0,PsgIns_00
; ; 		instrSlot insPBass3,0,PsgIns_00				; If using bass/noise type 3, NOISE will grab the frequency from chnl 3
; ; 		instrSlot insPNoise0,0,PsgIns_00
; ; 		instrSlot insPNoise1,0,PsgIns_00
; ; 		instrSlot insPNoise2,0,PsgIns_00
; ; 		instrSlot insPNoise3,0,PsgIns_00
; ; if using insFM6 instruments:
; ; .kick:	instrSmpl 0,WavIns_Kick,WavIns_Kick_e,WavIns_Kick	; sample flags (ex. loop), START, END, LOOP
; ; .snare:	instrSmpl 0,WavIns_Snare,WavIns_Snare_e,WavIns_Snare
; 
; ; ------------------------------------
; ; Track TESTME
; ; ------------------------------------
; 
; MusicBlk_TestMe:
; 		binclude "game/sound/music/lasttest_blk.bin"		; BLOCKS data
; MusicPat_TestMe:
; 		binclude "game/sound/music/lasttest_patt.bin"		; PATTERN data
; MusicIns_TestMe:
; 		instrSlot      insFM,0,FmIns_Piano_Small
; 		instrSlot     insFM3,0,FmIns_Fm3_OpenHat
; 		instrSlot     insFM3,0,FmIns_Fm3_ClosedHat
; 		instrSlot     insFM6,-18,.kick
; 		instrSlot     insFM6,-18,.snare
; 		instrSlot     insPSG,0,PsgIns_00
; 		instrSlot insPBass0,0,PsgIns_00
; 		instrSlot insPBass1,0,PsgIns_00
; 		instrSlot insPBass2,0,PsgIns_00
; 		instrSlot insPBass3,0,PsgIns_00
; 		instrSlot insPNoise0,0,PsgIns_00
; 		instrSlot insPNoise1,0,PsgIns_00
; 		instrSlot insPNoise2,0,PsgIns_00
; 		instrSlot insPNoise3,0,PsgIns_00
; .kick:	instrSmpl 0,WavIns_Kick,WavIns_Kick_e,WavIns_Kick
; .snare:	instrSmpl 0,WavIns_Snare,WavIns_Snare_e,WavIns_Snare
; 
; ; ------------------------------------
; ; Track Gigalo
; ; ------------------------------------
; 
; MusicBlk_Gigalo:
; 		binclude "game/sound/music/gigalo_psg_blk.bin"
; MusicPat_Gigalo:
; 		binclude "game/sound/music/gigalo_psg_patt.bin"
; MusicIns_Gigalo:
; 		instrSlot     insPSG,0,PsgIns_01
; 		instrSlot insPNoise0,0,PsgIns_01
; 		instrSlot insPNoise1,0,PsgIns_01
; 		instrSlot insPNoise2,0,PsgIns_01
; 
; ; ------------------------------------
; ; Track JackRab
; ; ------------------------------------
; 
; MusicBlk_JackRab:
; 		binclude "game/sound/music/jackrab_blk.bin"		; BLOCKS data
; MusicPat_JackRab:
; 		binclude "game/sound/music/jackrab_patt.bin"		; PATTERN data
; MusicIns_JackRab:
; 		instrSlot -1
; 		instrSlot insFM,0,FmIns_Ambient_spook
; 		instrSlot insFM6,+12,.tom
; 		instrSlot insFM6,+12,.kick
; 		instrSlot insPNoise0,0,PsgIns_02
; 		instrSlot insFM,0,FmIns_bass_synth
; 		instrSlot insFM6,+6,.cuban
; 		instrSlot insFM,0,FmIns_piano_m1
; 		instrSlot insFM6,-17,.middle
; 		instrSlot insFM,0,FmIns_Bass_3		; 10
; 		instrSlot insPSG,0,PsgIns_01
; 		instrSlot insFM,0,FmIns_ambient_dark
; 		instrSlot insPNoise1,0,PsgIns_00
; 		instrSlot insFM,0,FmIns_Ding_toy
; 		instrSlot insPSG,0,PsgIns_01
; 		instrSlot insFM6,+12,.snare
; 		instrSlot -1
; 		instrSlot insFM,0,FmIns_Trumpet_2
; 		instrSlot insPNoise0,0,PsgIns_00
; 		instrSlot insPSG,0,PsgIns_00		; 20
; 		instrSlot -1
; 		instrSlot -1
; 		instrSlot -1
; 		instrSlot -1
; .kick:		instrSmpl 0,WavIns_CLASIC02,WavIns_CLASIC02_e,WavIns_CLASIC02
; .snare:		instrSmpl 0,WavIns_SNOWD2,WavIns_SNOWD2_e,WavIns_SNOWD2
; .tom:		instrSmpl 0,WavIns_AFRICA2,WavIns_AFRICA2_e,WavIns_AFRICA2
; .cuban:		instrSmpl 0,WavIns_CUBAN,WavIns_CUBAN_e,WavIns_CUBAN
; .middle		instrSmpl 0,WavIns_MIDDLE,WavIns_MIDDLE_e,WavIns_MIDDLE

; ------------------------------------

		dephase		; close bank
		
; ----------------------------------------------------
; Sample data
; 
; can be anywhere in ROM
; ----------------------------------------------------

		align $8000
; WavIns_Kick:	binclude "game/sound/instr/dac/gems/12.wav",$2C
; WavIns_Kick_e:
; 
; WavIns_Snare:	binclude "game/sound/instr/dac/gems/8.wav",$2C
; WavIns_Snare_e:
; 
; WavIns_CLASIC02:
; 		binclude "game/sound/instr/dac/CLASIC02.wav",$2C
; WavIns_CLASIC02_e:
; 
; WavIns_SNOWD2:
; 		binclude "game/sound/instr/dac/SNOWD2.wav",$2C
; WavIns_SNOWD2_e:
; 
; WavIns_AFRICA2:
; 		binclude "game/sound/instr/dac/AFRICA2.wav",$2C
; WavIns_AFRICA2_e:
; 
; WavIns_CUBAN:
; 		binclude "game/sound/instr/dac/CUBAN.wav",$2C
; WavIns_CUBAN_e:
; 
; WavIns_MIDDLE:
; 		binclude "game/sound/instr/dac/MIDDLE.wav",$2C
; WavIns_MIDDLE_e:
