; ====================================================================
; ----------------------------------------------------------------
; MD ROM BANK other than DMA graphics, 1MB maximum
; 
; ($900000-$9FFFFF)
; ----------------------------------------------------------------

		align 4
; 		dc.b "MD ROM BANK 0"
CAMERA_ANIM:	binclude "data/mars/objects/anim/camera_anim.bin"
		align 4
