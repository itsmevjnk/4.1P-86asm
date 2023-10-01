floppy.img: bootload.bin
	cp $< $@
	truncate -s 1474560 $@

bootload.bin: bootload.asm
	nasm -f bin -o $@ $< -l $@.lst

clean:
	rm -f bootload.bin floppy.img bootload.bin.lst