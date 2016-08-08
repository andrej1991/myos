ISOMAKER = mkisofs

iso_image: bootloader kernel
	$(ISOMAKER) -R -J -c boot/bootcat -b boot/boot.bin -no-emul-boot -boot-load-size 4 -o ../ISO_image/myos.iso ../ISO_source

kernel:
	make -f ./Kernel/makefile

bootloader:
	make -f ./Bootloader/makefile

clean:
	find ./ -name "*.o" -delete
	find ./ -name "*.bin" -delete
