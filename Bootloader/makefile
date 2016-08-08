AS = $(HOME)/cross_compiler/bin/i686-elf-as
LD = $(HOME)/cross_compiler/bin/i686-elf-ld
BOOTLOADER_OBJECTS = ./Bootloader/boot.o ./Bootloader/print.o ./Bootloader/read_atapi.o ./Bootloader/interrupt.o ./Bootloader/read_from_iso9660.o


bootsector:
	$(AS) ./Bootloader/boot.s -o ./Bootloader/boot.o 
	$(AS) ./Bootloader/print.s -o ./Bootloader/print.o
	$(AS) ./Bootloader/interrupt.s -o ./Bootloader/interrupt.o
	$(AS) ./Bootloader/read_atapi.s -o ./Bootloader/read_atapi.o
	$(AS) ./Bootloader/read_from_iso9660.s -o ./Bootloader/read_from_iso9660.o
	$(LD) -Ttext-segment=0x7c00 --oformat=binary $(BOOTLOADER_OBJECTS) -o ../ISO_source/boot/boot.bin
