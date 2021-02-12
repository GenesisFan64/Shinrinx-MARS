# Shinrinx-MARS
A 3D Polygon system for the Sega 32X, inspired by the Zyrinx tech demo

This is a rewrite of MdlRenderer-MARS, now it uses the Watchdog interrupt to draw the polygons

** NTSC Systems only, Untested on PAL **

Features:
- Reads model objects, a Python script is used to convert .obj models to the format used in the renderer
- Model faces can use both triangles and quads
- Materials are both solid color and textures in any size but limited to SVDP mode 1 (255 colors + transparent color)
- Animation, for both Objects and Camera, Python converts .chan animation files for use in the renderer
- Layout support, to make big maps using separate model files

Current issues:
- NOT WORKING ON HARDWARE due to a problem with the MD-to-32X communication implemented, it will be fixed asap.
- RESET has 90% chances on HW
- Perspective is not perfect. It works well with solid colors but not for textures, Darxide and even the Zyrinx tech demo has problems with Perspective.
- Texture points in triangles might not map correctly (not sure if it a bug in the script or a limitation of DDA)

Please note that current 32X emulators ignore critical parts of the system, these include:
- RV bit: This bit reverts the ROM map back to normal temporally, meant as a workaround for the DMA's ROM-to-VDP transfers, if you do any transfer without setting this bit, the DMA will transfer trash data (Also, your DMA transfer routines MUST be located on RAM), SH2 side: If the bit is set and tries to read from ROM, it will read trash data or freeze the CPU
- FM bit: This bit tells which system side (Genesis or 32X) can read/write to the Super VDP (The framebuffer and 256-color palette), if a CPU with NO permission touches the Super VDP, it will freeze the entire system (32X or Genesis)
- BUS fighting (SH2 side): If any of the CPU read the same adresss, you will get bad results, mostly a freeze.

So if possible, please test this on real hardware. a prebuilt binary is located in the /out folder (rom_mars.bin) for testing, NTSC speed.

For more info check the official hardware manual (32X Hardware Manual.pdf)
