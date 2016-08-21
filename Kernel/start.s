.text

cli
jmp     _start

.global old_gdtr_content
old_gdtr_content:
    .word   0
    .int    0

.global gdtr_content
gdtr_content:
    .word   0
    .int    0

.globl _start
_start:
    lea     gdtr_content, %ebx
    call    get_gdt_base
    movl    %eax, %ds:2(%ebx)
    sgdt    (old_gdtr_content)
    call    initialize_memory
    movw    $8, %dx
    mulw    %dx
    decw    %ax
    movw    %ax, %ds:(%ebx)
    jmp     $8, $loadgdt
    loadgdt:
    lgdt    (gdtr_content)
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

