.code32
##Floppy registers
.equ STATUS_REG_A, 0x3F0
.equ STATUS_REG_B, 0x3F1
.equ DOR, 0x3F2
.equ TAPE_DRIVE, 0x3F3
.equ MAIN_SR, 0x3F4
.equ DATA_SEL_REG, 0x3F4
.equ FIFO, 0x3F5
.equ DIR, 0x3F7
.equ CONFIG_CR, 0x3F7

##Floppy commands
.equ READ_TRACK,2
.equ SPECIFY,3
.equ SENSE_DRIVE_STATUS,4
.equ WRITE_DATA,5
.equ READ_DATA,6
.equ RECALIBRATE,7
.equ SENSE_INTERRUPT,8
.equ WRITE_DELETED_DATA,9
.equ READ_ID,10
.equ READ_DELETED_DATA,12
.equ FORMAT_TRACK,13
.equ DUMP_REG, 14
.equ SEEK,15
.equ VERSION,16
.equ SCAN_EQUAL,17
.equ PERPENDICULAR_MODE,18
.equ CONFIGURE,19
.equ LOCK_COMM,20
.equ VERIFY,22
.equ SCAN_LOW_OR_EQUAL,25
.equ SCAN_HIGH_OR_EQUAL,29

gap_3_len:
	.int 0x1b

cylinder:
	.int 0x0
head:
	.int 0x0
sector:
	.int 0x1
drive:
	.int 0x0
sectors_to_read:
	.int 0x1


.equ parameter_loc, 5
.type pass_parameters, @function
pass_parameters:
/*when calling the function push the first parameter first, and then respectively the 2nd, 3rd ...
and lastly the number of the parameters*/
	push	%eax
	push	%edx
	push	%ecx
	push	%ebp
	mov	%esp,%ebp
	mov	$parameter_loc,%ecx
	mov	(%ebp,%ecx,4),%eax
	add	%eax,%ecx
	begin_param_pass:
	cmp	$parameter_loc,%ecx
	jz		end_of_param_pass
	mov	$MAIN_SR,%edx
	wait_for_floppycontroller:
	inb	%dx,%al
	andb	$0xc0,%al
	cmpb	$0x80,%al
	jnz	wait_for_floppycontroller
	movl	$FIFO,%edx
	movl	(%ebp,%ecx,4),%eax
	outb	%al,%dx
	/*push	%eax
	call	printreg
	push	$10
	call	printchar*/
	dec	%ecx
	jmp	begin_param_pass
	end_of_param_pass:
	mov	$MAIN_SR,%edx
	inb	%dx,%al
	/*push	%eax
	call	printreg
	push	$10
	call	printchar*/
	mov	%ebp,%esp
	pop	%ebp
	pop	%ecx
	pop	%edx
	pop	%eax
	ret
	

.global init_floppy
.type init_floppy, @function	
init_floppy:
	push	%eax
	push	%edx
	push	%ecx
	push	%ebp
	mov	%esp,%ebp
	mov	$MAIN_SR,%edx
	inb	%dx,%al
	andb	$0xc0,%al
	cmpb	$0x80,%al
	jz		start_init
	call	floppy_controller_reset
	jmp	init_floppy
	start_init:
	movl	$FIFO,%edx
	movl	$CONFIGURE,%eax
	outb	%al,%dx
	pushl	$0x0
	pushl	$0x60
	pushl	$0x0
	pushl	$0x3
	call	pass_parameters
	
	mov	$FIFO,%edx
	movl	$SPECIFY,%eax
	outb	%al,%dx
	pushl	$0x00
	pushl	$0x01
	pushl	$0x02
	call	pass_parameters
	#call	check_floppy_version
	mov	%ebp,%esp
	pop	%ebp
	pop	%ecx
	pop	%edx
	pop	%eax
	ret
	
	
.global select_floppy
.type select_floppy, @function	
select_floppy:
	push	%eax
	push	%edx
	push	%ecx
	mov	$0x14,%eax
	mov	$DOR,%edx
	outb	%al,%dx
	movl	$0x00ffffff,%ecx
	wsf:
	nop
	loop	wsf
	call	init_floppy
	pop	%ecx
	pop	%edx
	pop	%eax
	ret

floppy_controller_reset:
	push	%eax
	push	%edx
	push	%ecx
	movl	$DOR,%edx
	inb	%dx,%al
	orb	$0x4,%al
	outb	%al,%dx
	movl	$0xffff,%ecx
	wfcr:
	nop
	loop	wfcr
	andb	$0b11111011,%al
	outb	%al,%dx
	movl	$0xffffff,%ecx
	wfcr2:
	nop
	loop wfcr2
	call select_floppy
	pop	%ecx
	pop	%edx
	pop	%eax
	ret

check_floppy_version:
	push	%eax
	push	%eax
	push	%ecx
	mov	$MAIN_SR,%edx
	inb	%dx,%al
	andb	$0xc0,%al
	cmp	$0x80,%al
	jz		cfvsuccess
	call	floppy_controller_reset
	cfvsuccess:
	mov	$FIFO,%edx
	mov	$VERSION,%eax
	outb	%al,%dx
	mov	$MAIN_SR,%dx
	verify_command_success:
	inb	%dx,%al
	andb	$0xc0,%al
	cmpb	$0xc0,%al
	jnz	verify_command_success
	mov	$FIFO,%dx
	inb	%dx,%al
	push	%eax
	#call	printreg
	pop	%eax
	pop	%ecx
	pop	%edx
	pop	%eax
	ret


.global read_floppy
.type read_floppy, @function	
read_floppy:
	push	%eax
	push	%edx
	push	%ecx
	push	%ebp
	mov		%esp,%ebp
	xor		%eax,%eax
	call	initialize_floppy_DMA
	call	prepare_for_floppy_DMA_read
	start_of_function_read_floppy:
	movl	$0x8000,%ecx
	mov	$MAIN_SR,%edx
	inb	%dx,%al
	andb	$0xc0,%al
	cmpb	$0x80,%al
	jz		start_read
	call	floppy_controller_reset
	jmp	start_of_function_read_floppy
	start_read:
	movl	$READ_DATA,%eax
	orb		$0x80,%al
	orb		$0x40,%al	
	movl	$FIFO,%edx
	outb	%al,%dx
	xor		%eax,%eax
	movb	head,%al
	shrw	$0x2,%ax
	orb		drive,%al
	push	%eax
	pushl	cylinder
	pushl	head
	pushl	sector
	pushl	$0x02
	pushl	sectors_to_read
	pushl	gap_3_len
	pushl	$0xff
	pushl	$0x08
	call	pass_parameters
	#execution phase
	read_data:
	xor		%eax,%eax
	mov		$FIFO,%edx
	inb		%dx,%al
	/*push	%eax
	call	printreg
	push	$10
	call	printchar*/
	movb	%al,(%ecx)
	inc		%ecx
	mov		$MAIN_SR,%edx
	inb		%dx,%al
	andb	$0xe0,%al
	cmpb	$0xe0,%al
	jz		read_data
	#result phase
	read_result_bytes:
	mov		$MAIN_SR,%edx
	inb		%dx,%al
	testb	$0x80,%al
	jz		read_result_bytes
	andb	$0x50,%al
	cmpb	$0x50,%al
	jnz		end_of_read
	mov		$FIFO,%edx
	inb		%dx,%al
	push	%eax
	#call	printreg
	push	$newline
	#call	printstr
	jmp	read_result_bytes
	end_of_read:
	/*mov	$0x00ffffff,%ecx
	p:
	nop
	loop	p
	mov	$MAIN_SR,%edx
	inb	%dx,%al
	push	%eax
	call	printreg*/
	mov	%ebp,%esp
	pop	%ebp
	pop	%ecx
	pop	%edx
	pop	%eax
	ret
	
.global dumpreg
.type dumpreg, @function
dumpreg:
	push	%eax
	push	%edx
	push	%ebp
	mov	%esp,%ebp
	mov	$DUMP_REG,%eax
	mov	$FIFO,%edx
	outb	%al,%dx
	read_result_bytesx:
	mov	$MAIN_SR,%edx
	inb	%dx,%al
	testb	$0x80,%al
	jz		read_result_bytesx
	andb	$0x50,%al
	cmpb	$0x50,%al
	jnz	end_of_readx
	mov	$FIFO,%edx
	inb	%dx,%al
	push	%eax
	call	printreg
	push	$newline
	call	printstr
	jmp	read_result_bytesx
	end_of_readx:
	push	$10
	call	printchar
	mov	$DOR,%edx
	inb	%dx,%al
	push	%eax
	call	printreg
	push	$10
	call	printchar
	mov	%ebp,%esp
	pop	%ebp
	pop	%edx
	pop	%eax
	ret
	
	
initialize_floppy_DMA:
# set DMA channel 2 to transfer data from 0x1000 - 0x33ff in memory
# paging must map this _physical_ memory elsewhere and _pin_ it from paging to disk!
# set the counter to 0x23ff, the length of a track on a 1.44 MiB floppy - 1 (assuming 512 byte sectors)
# transfer length = counter + 1
	push	%eax
	push	%edx
	mov	$0x06,%eax
	mov	$0x0a,%edx
   out 	%al,%dx      # mask DMA channel 2 and 0 (assuming 0 is already masked)
   mov	$0xff,%eax
   mov	$0x0c,%edx
   out	%al,%dx      # reset the master flip-flop
   mov	$0,%eax
   mov	$0x04,%edx
   out 	%al,%dx         # address to 0 (low byte)
   mov	$0x80,%eax
   mov	$0x04,%edx
   out 	%al,%dx      # address to 0x80 (high byte)
   mov	$0xff,%eax
   mov	$0x0c,%edx
   out 	%al,%dx      # reset the master flip-flop (again!!!)
   mov	$0xff,%eax
   mov	$0x05,%edx
   out 	%al,%dx      # count to 0x1ff(low byte)
   mov	$0x1,%eax
   mov	$0x05,%edx
   out 	%al,%dx      # count to 0x1ff (high byte),
   mov	$0x00,%eax
   mov	$0x81,%edx
   out 	%al,%dx         # external page register to 0 for total address of 00 10 00
   mov	$0x2,%eax
   mov	$0xa,%edx
   out 	%al,%dx      # unmask DMA channel 2
   pop	%edx
   pop	%eax
   ret
   
   
   
   
prepare_for_floppy_DMA_read:
	push	%eax
	push	%edx
	mov	$0x6,%eax
	mov	$0xa,%edx
   out 	%al,%dx      # mask DMA channel 2 and 0 (assuming 0 is already masked)
   mov	$0x4a,%eax
   mov	$0x0b,%edx
   out 	%al,%dx      # 01010110
                        # single transfer, address increment, autoinit, read, channel2)
   mov	$0x2,%eax
   mov	$0xa,%edx
   out 	%al,%dx      # unmask DMA channel 2
   pop	%edx
   pop	%eax
   ret
