.code32
#include header.h

idttest:
    .asciz "some interrupt happened\n"

debug:
    .asciz "interrupt debugging\n"

.global StartOfIDT
StartOfIDT:
/*    .rep 6
    .word   my_general_interrupt_handler
    .word   8
    .byte   0
    .byte   0b10001111
    .word   0
    .endr

    .word   debug_interrupt_handler
    .word   8
    .byte   0
    .byte   0b10001111
    .word   0*/

    .rep 46
    .word   my_general_interrupt_handler
    .word   8
    .byte   0
    .byte   0b10001111
    .word   0
    .endr

    .word   ide_interrupt_1
    .word   8
    .byte   0
    .byte   0b10001110
    .word   0

    .word   ide_interrupt_1
    .word   8
    .byte   0
    .byte   0b10001110
    .word   0
IDTend:

.global IDTdescriptor
IDTdescriptor:
    .word 2047
    .int    StartOfIDT

end_interrupt:
#notifies the PIC about the end of interrupt
    mov     $0xa0,%dx
    mov     $0x20,%al
    out     %al,%dx
    mov     $0x20,%al
    mov     $0x20,%Dx
    out     %al,%dx
    ret

.equ MASTER_PIC_COMMAND, 0x20
.equ MASTER_PIC_DATA, 0x21
.equ SLAVE_PIC_COMMAND, 0xa0
.equ SLAVE_PIC_DATA, 0xa1

.global Init_interrupts
.type Init_interrupts, @function
Init_interrupts:
    pusha
    lidt    (IDTdescriptor)
    xor     %ecx,%ecx
    #starting the initialization
    mov     $MASTER_PIC_COMMAND,%dx
    mov     $0x11,%al
    out     %al,%dx
    call	iowait
    mov     $SLAVE_PIC_COMMAND,%dx
    mov     $0x11,%al
    out     %al,%dx
    call	iowait
    #providing the offset for the irqs
    mov     $0x20,%al
    mov     $MASTER_PIC_DATA,%dx
    out     %al,%dx
    call	iowait
    mov     $SLAVE_PIC_DATA,%dx
    mov     $0x28,%al
    out     %al,%dx
    call	iowait
    #tell Master PIC that there is a slave PIC at IRQ2 (0000 0100)
    mov     $4,%al
    mov     $MASTER_PIC_DATA,%dx
    out     %al,%dx
    call	iowait
    #tell Slave PIC its cascade identity (0000 0010)
    mov     $2,%al
    mov     $SLAVE_PIC_DATA,%dx
    out     %al,%dx
    call	iowait
    #set up 8086/88 (MCS-80/85) mode for master and slave also
    mov     $MASTER_PIC_DATA,%dx
    mov     $0x01,%al
    out     %al,%dx
    call	iowait
    mov     $SLAVE_PIC_DATA,%dx
    mov     $0x01,%al
    out     %al,%dx
    #masking the interrupts
    #set requiered bit 0 to enable an interrupt
    call	iowait
    mov     $0xf9,%al
    mov     $MASTER_PIC_DATA,%dx
    out     %al,%dx
    mov     $0x3f,%al
    mov     $SLAVE_PIC_DATA,%dx
    out     %al,%dx
    popa
    sti
    ret

.global debug_interrupt_handler
.type debug_interrupt_handler, @function
debug_interrupt_handler:
    lea     debug,%eax
    push    %eax
    call    printstr
    pop     %eax
    call    end_interrupt
    iret

.global my_general_interrupt_handler
.type my_general_interrupt_handler, @function
my_general_interrupt_handler:
    lea     idttest,%eax
    push    %eax
    call    printstr
    pop     %eax
    call    end_interrupt
    iret


.global ide_interrupt_1
.type ide_interrupt_1, @function
ide_interrupt_1:
    movb    $1, cd_dvd_interrupt_happened
    push    %eax
    movw    $0x1F7, %dx
    inb     %dx, %al
    pop     %eax
    call    end_interrupt
    iret

/*.global keyboard_interrupt
.type keyboard_interrupt, @function
keyboard_interrupt:
    lea     keybrd_interrupt, %eax
    push    %eax
    call    printstr
    pop     %eax
    call    end_interrupt
    iret


/*.global my_keyboard_handler
.type my_keyboard_handler, @function
my_keyboard_handler:
    pusha
    mov     %esp,%ebp
    xor     %eax,%eax
    polldataport:
    mov     $0x64,%dx
    in      %dx,%al
    andb    $1,%al
    jz      polldataport
    readin:
    mov	$0x60,%dx
    in      %dx,%al
    push    %eax
    call    printreg
    call    end_interrupt
    lea     keybrd_interrupt,%eax
    push    %eax
    call    printstr
    mov     %ebp,%esp
    popa
    iret*/

