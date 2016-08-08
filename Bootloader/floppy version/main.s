#offset 0x0
#codesegment 0x50
#datasegment 0x0

#pusha -> order: EAX, ECX, EDX, EBX, ESP, EBP, ESI, EDI. The value of ESP pushed is the value before the instruction is executed.

#bármely %BP -t nem tartalmazó címzési mód (bázis/index/relarív ill. ezek kombinációi) az adatsegmenst (%DS) fogja alapértelmezetten használni
#a %BP -t tartalmazócímzési módok a %SS -t fogják alapértelmezetten használni
#az alapértelmezés a %"szegmensregiszter": (pl %DS:) felülbírálható
.code16
.text	
.globl _start;

_start:
	mov	$0x1050,%ax
	mov	%ax,%ss
	mov	0xffff,%ax
	mov	%ax,%sp
	xor	%ax,%ax
	jmp	main
	
	#.word	0xffff
	

StartOfGDT:
	zerodescriptor:
		.rep	4
		.word 0
		.endr
	OScode:
		.word 0xa00
		.word 0
		.byte 0
		.byte 0x9a
		.byte 0xc0
		.byte 0
	OSdata:
		.word 0xa00
		.word 0
		.byte 0
		.byte 0x92
		.byte 0xc0
		.byte 0
	OSstack:
		.word 0x100
		.word 0
		.byte 0x50
		.byte 0x96
		.byte 0xc0
		.byte 1
	GDTend:
	
	GDTdescriptor:			
		.word	0x1f
		.int	StartOfGDT
		#.word	0xffff
###############################################
##############################################
/*.global StartOfIDT
	StartOfIDT:
		.rep 32
		.word	my_general_interrupt_handler
		.word	8
		.byte 0
		.byte	0b10001111
		.word 0
		.endr
		
		.word	my_general_interrupt_handler
		.word	8
		.byte 0
		.byte	0b10001110
		.word 0
		
		.word	my_keyboard_handler
		.word	8
		.byte 0
		.byte	0b10001110
		.word 0
		
		.rep 4
		.word	my_general_interrupt_handler
		.word	8
		.byte 0
		.byte	0b10001110
		.word 0
		.endr
		
		.word	floppy_interrupt
		.word	8
		.byte 0
		.byte	0b10001110
		.word 0
		
		.rep 9
		.word	my_general_interrupt_handler
		.word	8
		.byte 0
		.byte	0b10001110
		.word 0
		.endr
	IDTend:

.global IDTdescriptor
	IDTdescriptor:
		.word 2047
		.int	StartOfIDT*/





.global target
target:
	.int 0x8000		
				
switsching_to_protected:
	cli
	lgdt	(GDTdescriptor)
	mov	%cr0,%eax
	or		$0x1,%ax
	mov	%eax,%cr0
	jmp	$8,$init_protected
	ret
	
main:
	call	switsching_to_protected
	jmp .		########################## endless loop



.code32


		
init_protected:
	mov		$0x10,%ax
	mov		%ax,%ds
	mov		%ax,%es
	mov		%ax,%fs
	mov		%ax,%gs
	mov		$24,%ax
	mov		%ax,%ss
	movb	$0x01,0xfec00000
	#call	Init_interrupts
	nop
	movl	0xfec00010,%eax
	push	%eax
	call	printreg
	push	$10
	call	printchar
	lea		welcome,%eax
	push	%eax
	call	printstr
	call	dumpreg
	call  	select_floppy
	#call	check_floppy_version
	call	read_floppy
	#int	$38
	mov	$20,%ecx
	mov	$0x8000,%ebx
	mov	$0,%edx
	/*xxx:
		movl	(%ebx,%edx,4),%eax
		push	%eax
		call	printreg
		lea	newline,%eax
		push	%eax
		call	printstr
		inc	%edx
	loop	xxx*/
	lea	endofrun,%eax
	push	%eax
	call printstr
	#call	list_all_PCI_device
	nop
	jmp	.		######################## endless loop
	
	
	
