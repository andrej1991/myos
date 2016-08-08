#.org 0x7c00
.code16

#hint the assembler that here is the executable code located
.text	
.globl _start;
#boot code entry
_start:
		xor		%ax,%ax
		movw	%ax,%es
		movw	%ax,%si
		mov		%ax,%ss
		mov		%ax,%ds
		mov		%ax,%gs
      jmp	_boot	    	                 
      failure: 
      	.asciz "failure\n\r" 
	  welcome:
		.asciz "FUCK YOU!!!\n\r"
      space:
      	.asciz " "
      newline:
      	.asciz "\n\r"
      head: 
      	.byte 0x1
      sect:
      	.byte 0x1
      cyl:
      	.byte 0x0
      loc_segment:		#a szaegmens címe amibe töltöm az adatot
      	.word	0x50
      loc_offset:			#az adat szegmensbeli offszetje
      	.word 0x0
      segments_to_load:
      	.byte 0x10
      
      
	reset_floppy:
      pusha
      movb	$0,%ah
      movb	$0,%dl
      int	$0x13
      popa
      ret

	.macro mWriteString str              #macro to print a string
     	pusha	
		leaw  \str, %si
		call	.writeStringIn
		popa
	.endm
     
	.writeStringIn:
		lodsb
		orb  %al, %al
		jz   .writeStringOut
		movb $0x0e, %ah
		int  $0x10
		jmp  .writeStringIn
		.writeStringOut:
		ret
     		
     		
	.macro writebyte_in_hex hex
		pusha
		movb	\hex,%cl
		movb	%cl,%al
		shrb	$4,%al
		call	printhex
		movb	%cl,%al
		andb	$0x0f,%al
		call	printhex
		mWriteString space
		popa
	.endm
		
	printhex:
		cmpb	$0xA,%al
		jl		lessthen_0xA
		addb	$0x37,%al
		movb	$0x0e,%ah
		int	$0x10
		ret
		lessthen_0xA:
		addb	$0x30,%al
		movb	$0x0e,%ah
		int	$0x10
		ret
			
	
	load_file_from_floppy:
		pusha	
		load_file_from_floppy_01:
		movw	loc_segment,%ax
		movw	%ax,%es					#location off buffer
		movw	loc_offset,%bx			#location off buffer
		movb	$0x02,%ah				#function of int 13h
		movb	segments_to_load,%al	#sectors to load
		movb	cyl,%ch					#cylinder / track
		movb	sect,%cl					#sector
		movb	head,%dh					#head
		movb	$0,%dl					#driver number
		int	$0x13
		jnc	loaded
		call	reset_floppy
		mWriteString failure
		jmp	load_file_from_floppy_01
		loaded:
		popa
		ret

			
		
_boot:
		call	load_file_from_floppy
		#ljmp	$0x50,$0x00
		movl	$0x500,%ebx
		movb	(%ebx),%al
		writebyte_in_hex %al
		mWriteString welcome
		jmp .
		. = _start + 510      #mov to 510th byte from 0 pos
		.word	0x55aa
		buffer:
