# Shinrinx-MARS
A 3D Polygon system for the Sega 32X, inspired by the Zyrinx tech demo

This is a rewrite of MdlRenderer-MARS, now it uses the Watchdog interrupt to draw the polygons

** For NTSC Systems, Untested on PAL **

Features:
- Reads model objects, a Python script is used to convert .obj models to the format used in the engine
- Model faces can use both triangles and quads
- Materials can use both solid color and textures limited to SVDP mode 1 (255 colors + transparent color)
- Simple animation: for both Objects and Camera, Python converts .chan animation files for use in the engine
- Map layout support: to make big maps using separate model pieces

Current issues:
- Soft-reset in real hardware might crash everything, probably because of outdated code from the 32XSDK.
- Perspective doesn't calculate properly outside of the camera: It's less noticiable with solid colors but textures are affected. Darxide and even the Zyrinx tech demo has problems with Perspective.
- Texture points in triangles might not map correctly, not sure if it a bug in the script or a limitation of DDA.

Please note that current 32X emulators ignore critical parts of the system, these include:
- RV bit: This bit reverts the ROM map back to normal temporary, meant as a workaround for the Genesis DMA's ROM-to-VDP transfers, If you do any transfer without setting this bit, the DMA will transfer trash data, And your DMA transfer routines MUST be located on RAM otherwise after setting RV=1 the next instruction will be corrupted becuase the ROM changed its location (from $880000 to $000000), for the SH2 side: if RV is set and ROM read will return trash data
- FM bit: This bit tells which system side (Genesis or 32X) can read/write to the Super VDP (The framebuffer and 256-color palette), if a CPU with NO permission touches the Super VDP, it will freeze the entire system (32X add-on or Genesis)
- BUS fighting on SH2: If any of the CPUs read the same adresss you will get bad results, mostly a freeze. (Note: Only encountered this on SDRAM area, the rest should be fine)
- SH2's DMA locks Palette: If transfering indexed-palette data to SuperVDP using DMA, the first transfer will work but after that, the DMA will get locked and then both Source and Destination areas can't be rewritten.

A prebuilt binary is located in the /out folder (rom_mars.bin) for testing, for NTSC systems.

For more info check the official hardware manual (32X Hardware Manual.pdf)
