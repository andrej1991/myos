TARGET = boot
GCC = gcc
Format_Floppy = mkfs.fat -F 12 -M 0xF9 -s 1 -f 1 -r 112 /dev/loop5
Copy_second_stage = cp ./stagetwo.bin ../../floppy
Copy_the_Bootloader = dd if=boot.bin of=/dev/loop5 conv=fsync


bootsector:	
	as boot.s -o boot.o
	ld -Ttext-segment=0x7c00 --oformat=binary boot.o -o boot.bin
	$(Copy_the_Bootloader)
	

#root privilege required	
mount_floppy:
	dd if=/dev/zero of=./floppy.img bs=1k count=1440
	sudo losetup /dev/loop5 ./floppy.img
	sudo $(Format_Floppy)
	sudo mount /dev/loop5 ../../floppy
	#sudo mount -o uid=1000,gid=1000,umask=777 /dev/loop5 ../floppy
	sudo chmod 777 /dev/loop5
	$(Copy_the_Bootloader)
	sudo $(Copy_second_stage)

remove_floppy:
	sudo umount /dev/loop5
	sudo losetup -d /dev/loop5
	
reset_floppy: remove_floppy mount_floppy bootsector

second_stage:
	as main.s -o main.o
	as print.s -o print.o
	as floppy.s -o floppy.o
	#as interrupt.s -o interrupt.o
	ld -Ttext-segment=0x500 --oformat=binary main.o floppy.o print.o -o stagetwo.bin
	dd if=stagetwo.bin of=/dev/loop5 obs=512 seek=18 conv=fsync
	#dd if=./FAT.img of=/dev/loop5 obs=512 seek=1 conv=fsync
	#sudo $(Copy_second_stage)
	#du -b ./stagetwo.bin > ./size
