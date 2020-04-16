; ====================================================================
; ----------------------------------------------------------------
; SH2 SDRAM user data
; 
; this data is stored on SDRAM, it's always available to use
; and can be writeable
; ----------------------------------------------------------------

		align 4
Polygn_Solid:	dc.w 3,600		; type, option
		dc.l $FF
PlygnTmp_X:	dc.w 128,64		; x--1
		dc.w   8,64		; 2--x
		dc.w   8,64		; 3--x
		dc.w 128,64		; x--4
		dc.w 600,  0
		dc.w   0,  0
		dc.w   0,555
		dc.w 600,555
		align 4
