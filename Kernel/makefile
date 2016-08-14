GCC = $(HOME)/cross_compiler/bin/i686-elf-gcc
AS = $(HOME)/cross_compiler/bin/i686-elf-as
LD = $(HOME)/cross_compiler/bin/i686-elf-ld

IO_OBJECTS = ./Kernel/IO/VGA_text_mode/print.o ./Kernel/IO/basic_io.o

MEMORY_OBJECTS = ./Kernel/Memory/initialize_memory.o ./Kernel/Memory/memory_management.o

kernel: in_out memory
	$(GCC) -mno-red-zone -c ./Kernel/main.c -o ./Kernel/main.o
	$(AS) ./Kernel/start.s -o ./Kernel/start.o
	$(LD) -Ttext-segment=0x100000 --oformat=binary ./Kernel/start.o ./Kernel/main.o $(IO_OBJECTS) $(MEMORY_OBJECTS) -o ../ISO_source/kernel/kernel.bin

in_out:
	$(AS) ./Kernel/IO/VGA_text_mode/print.s -o ./Kernel/IO/VGA_text_mode/print.o
	$(AS) ./Kernel/IO/basic_io.s -o ./Kernel/IO/basic_io.o

memory:
	$(GCC) -mno-red-zone -c ./Kernel/Memory/initialize_memory.c -o ./Kernel/Memory/initialize_memory.o
	$(GCC) -mno-red-zone -c ./Kernel/Memory/memory_management.c -o ./Kernel/Memory/memory_management.o
