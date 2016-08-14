.text

cli
jmp     _start


oldGDTdescriptor:
    .word   0
    .int    0

GDTdescriptor:
    .word   0
    .int    0

.globl _start
_start:
    call    get_gdt_base
    lea     GDTdescriptor, %ebx
    movl    %eax, %ds:2(%ebx)
    sgdt    (oldGDTdescriptor)
    call    initialize_memory
    movw    $8, %dx
    mulw    %dx
    decw    %ax
    movw    %ax, %ds:(%ebx)
    lgdt    (GDTdescriptor)
    movl    $0x10,%eax
    mov     %ax,%ds
    mov     %ax,%es
    mov     %ax,%fs
    mov     %ax,%gs
    mov     %ax,%ss
    jmp     $8,$next
    next:
    movl    $0x3FFE0, %eax
    movl    %eax, %esp
    call    main

