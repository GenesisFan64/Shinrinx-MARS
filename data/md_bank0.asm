; ====================================================================
; ----------------------------------------------------------------
; Single 68k DATA BANK for MD ($900000-$9FFFFF)
; for stuff other than DMA transfers
; 
; Maximum size: $0FFFFF bytes
; ----------------------------------------------------------------

		align $8000
TEST_BLOCKS	binclude "data/sound/tracks/temple_blk.bin"
TEST_PATTERN	binclude "data/sound/tracks/temple_patt.bin"
TEST_INSTR	dc.b 0,0
		dc.w zinsPsg_00
		
CAMERA_ANIM:	binclude "data/mars/objects/anim/camera_anim.bin"
		align 4

TEST_WAV:	binclude "data/sound/test.wav",$2C,$CFFFF
TEST_WAV_e:
