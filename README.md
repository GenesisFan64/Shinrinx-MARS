# Shinrinx-MARS
A 3D Polygon system for the Sega 32X, inspired by that tech demo

This is a rewrite of MdlRenderer-MARS, now it uses a special interrupt to draw the polygons

NTSC Systems only, needs to be tested on PAL

Current issues:
- Rewrite the routine that draws the polygons, it's a mess

Please note that current 32X emulators ignore critical parts of the system, these include:
- FM bit: This bit tells which system side (Genesis or 32X) can read/write to the Super VDP (The framebuffer and 256-color palette), if a CPU with NO permission touches the Super VDP, it will freeze the entire system (32X or Genesis)
- RV bit: This bit reverts the ROM map back to normal temporally, meant as a workaround for the DMA's ROM-to-VDP transfers, if you do any transfer without setting this bit, the DMA will transfer trash data, ALSO: if you store your DMA transfer routine on ROM, setting this bit will cause the next 68k instruction to be garbage since the ROM data moved it's location, all your transfer routines should be stored on RAM instead.
- BUS fighting: If any of the CPU poke the same adresss, you will get weird results, mostly a full freeze

So if possible, please test any changes on real hardware.

For more info check the official hardware manual (32X Hardware Manual.pdf)
