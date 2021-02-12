; ====================================================================
; ----------------------------------------------------------------
; Single 68k DATA BANK for MD ($900000-$9FFFFF)
; for stuff other than DMA transfers
; 
; Maximum size: $0FFFFF bytes
; ----------------------------------------------------------------

		align 4
CAMERA_ANIM:	binclude "data/mars/objects/anim/camera_anim.bin"
		align 4
TEST_WAV:	binclude "data/sound/test.wav",$2C,$020000
TEST_WAV_e:
