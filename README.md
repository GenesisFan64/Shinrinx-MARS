# Shinrinx-MARS
A 3D Polygon system for the Sega 32X, inspired by that tech demo

This is a rewrite of MdlRenderer-MARS, now it uses a special interrupt to draw the polygons

NTSC Systems only, needs to be tested on PAL

Current issues/plans:
- Probably rework the perspective routine
- Fix the bubble sort when faces are lower than < 2

Please note that current 32X emulators ignore critical parts of the system, these include:
- FM bit: This bit tells which system side (Genesis or 32X) can read/write to the Super VDP (The framebuffer and 256-color palette), if a CPU with NO permission touches the Super VDP, it will freeze the entire system (32X or Genesis)
- RV bit: This bit reverts the ROM map back to normal temporally, meant as a workaround for the DMA's ROM-to-VDP transfers, if you do any transfer without setting this bit, the DMA will transfer trash data (Also, your DMA transfer routines MUST be located on RAM), SH2 side: If the bit is set and tries to read from ROM, it crashes the CPU entirely
- BUS fighting: If any of the CPU poke the same adresss, you will get bad results, mostly a full freeze

So if possible, please test any changes on real hardware.

For more info check the official hardware manual (32X Hardware Manual.pdf)
