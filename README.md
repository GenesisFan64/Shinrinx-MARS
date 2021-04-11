# Shinrinx-MARS
A 3D Polygon system for the Sega 32X, inspired by the Zyrinx tech demo

This is a rewrite of MdlRenderer-MARS, it uses the Watchdog interrupt to draw the polygons on the background

** For NTSC Systems, Untested on PAL **

Features:
- Reads model objects, a Python script is used to convert .obj models to the format used in the engine
- Model faces can use both triangles and quads
- Materials can use both solid color and textures but limited to SVDP mode 1 (255 colors + transparent color)
- Simple animation: for both Objects and Camera, Python converts .chan animation files for use in the engine
- Map layout support: to make big maps using separate model pieces

Current issues/notes:
- Soft-reset might freeze everything (65% chance)
- Perspective calculation is weak, doesn't work properly outside of the camera (Darxide and even the Zyrinx tech demo has problems with perspective)
- Solid-color polygons might loose lines
- Texture points in triangles might not map correctly, not sure if it a bug in the script or a limitation of DDA.

Please note that current 32X emulators ignore some hardware restrictions and bugs of the system:
- RV bit: This bit reverts the ROM map back to normal temporary, meant as a workaround for the Genesis DMA's ROM-to-VDP transfers, If you do any transfer without setting this bit, the DMA will transfer trash data, And your DMA transfer routines MUST be located on RAM otherwise after setting RV=1 the next instruction will be trash becuase the ROM changed its location (from $880000 to $000000), for the SH2 side: if RV is set, any read from SH2's ROM area will return trash data
- FM bit: This bit tells which system side (Genesis or 32X) can read/write to the Super VDP (The framebuffer and 256-color palette), if a CPU with no permission touches the Super VDP, it will freeze the entire system (32X add-on or Genesis)
- BUS fighting on SH2: If any of the SH2 CPUs read/write the same location you will get bad results, mostly a freeze. (Note: Only encountered this on SDRAM area, other locations like the registers should be fine)
- SH2's DMA locks Palette (HW bug I found, or probably did something wrong): If transfering indexed-palette data to SuperVDP's Palette using DMA, the first transfer will work, then the DMA will get locked, both Source and Destination areas can't be rewritten
- PWM's sound limit (for each channel: Left and Right) is $3FF, not $FFF mentioned in the docs

A prebuilt binary is located in the /out folder (rom_mars.bin) for testing, works on any Genesis/MD flashcart WITH the 32X already inserted, If it doesn't boot: it probably broke during coding, ROM is for NTSC systems, can be played on PAL but with slowdown.

For more info check the official hardware manual (32X Hardware Manual.pdf)
