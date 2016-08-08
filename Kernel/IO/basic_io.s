.global inbyte
.type inbyte, @function
inbyte:
    push    %edx
    push    %ebp
    mov     %esp, %ebp
    xor     %eax, %eax
    movl    12(%ebp), %edx
    inb     %dx, %al
    pop     %ebp
    pop     %edx
    ret

.global inword
.type inword, @function
inword:
    push    %edx
    push    %ebp
    mov     %esp, %ebp
    xor     %eax, %eax
    movl    12(%ebp), %edx
    inw     %dx, %ax
    pop     %ebp
    pop     %edx
    ret

.global outbyte
.type outbyte, @function
outbyte:
    push    %edx
    push    %ebp
    mov     %esp, %ebp
    movl    12(%ebp), %eax
    movl    16(%ebp), %edx
    outb    %al, %dx
    pop     %ebp
    pop     %edx
    ret

.global outword
.type outword, @function
outword:
    push    %edx
    push    %ebp
    mov     %esp, %ebp
    movl    12(%ebp), %eax
    movl    16(%ebp), %edx
    outw    %ax, %dx
    pop     %ebp
    pop     %edx
    ret
