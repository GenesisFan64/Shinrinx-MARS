; ====================================================================
; ----------------------------------------------------------------
; DMA ROM DATA Transfer section, no bank limitations
; 
; RV bit must be set to access here
; ----------------------------------------------------------------

		align $8000
MdGfx_Bg:
		binclude "data/md/bg/bg_art.bin"
MdGfx_Bg_e:	align 2
