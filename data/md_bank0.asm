; ====================================================================
; ----------------------------------------------------------------
; Single 68k DATA BANK for MD ($900000-$9FFFFF)
; for stuff other than DMA transfers
; 
; Maximum size: $FFFFF bytes
; ----------------------------------------------------------------

		align 4
CAMERA_ANIM:	binclude "data/mars/objects/anim/camera_anim.bin"
		align 4
