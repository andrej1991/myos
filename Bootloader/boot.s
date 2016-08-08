.code16


.text
.globl _start
_start:
    mov     $0x2403, %ax                #;--- A20-Gate Support ---
    int     $0x15
    jb      a20_ns                  #;INT 15h is not supported
    cmp     $0, %ah
    jnz     a20_ns                  #;INT 15h is not supported

    mov     $0x2402, %ax                #;--- A20-Gate Status ---
    int     $0x15
    jb      a20_failed              #;couldn't get status
    cmp     $0, %ah
    jnz     a20_failed              #;couldn't get status

    cmp     $1, %al
    jz      a20_activated           #;A20 is already activated

    mov     $0x2401, %ax                #;--- A20-Gate Activate ---
    int     $0x15
    jb      a20_failed              #;couldn't activate the gate
    cmp     $0, %ah
    jnz     a20_failed              #;couldn't activate the gate
    a20_activated:                  #;go on
    jmp     go_on
    a20_failed:
    a20_ns:
    jmp     .
    go_on:
    jmp    detect_memory
    end_of_detect_memory:
    xor     %ax,%ax
    movw    %ax,%es
    movw    %ax,%si
    mov     %ax,%ss
    mov     %ax,%ds
    mov     %ax,%gs
    jmp     switsching_to_protected

/* base address of code and data segment is 0x0
   limit for code and data segment is 0xfffff
   code segment access byte: 0b10011010
   data segment access byte: 0b10010010
   stack base: 0xAC00
   stack limit: 0x05
   stack segment access byte: 0b10010110
   the granuality and size flag is set for all the segments*/

## 0x3FFE0 = 0x40000 - 0x20
.equ STACKPOINTER_TOP, 0x3FFE0
StartOfGDT:
    zerodescriptor:
        .quad   0
    OScode:
        .quad   0x00CF9A000000FFFF
    OSdata:
        .quad   0x00CF92000000FFFF
/*    OSstack:
        .quad   0x00C09600AC000005*/
    GDTend:

GDTdescriptor:
    .word   0x17
    .int    StartOfGDT


detect_memory:
    movl    $0x4010, %eax
    movw    %ax, %es
    movl    $0x4, %edi
    xor     %ebx, %ebx
    xor     %esi, %esi
    movl    $0x534D4150, %edx
    movl    $24, %ecx
    movl    $0xE820, %eax
    int     $0x15
    cmp     %edx, %eax
    jnz     failure
    movl    %ecx, %es:24(%di)
    start_of_mem_detection:
        inc     %esi
        movl    $24, %ecx
        addl    $28, %edi
        movl    $0xE820, %eax
        int     $0x15
        jc      end_of_detection
        cmp     $0x0, %ebx
        jz      end_of_detection
        movw    %cx, %es:-4(%di)
        jmp     start_of_mem_detection
    end_of_detection:
    xor     %edi, %edi
    movw    %si, %es:(%di)
    jmp     end_of_detect_memory
    failure:
    jmp     .

switsching_to_protected:
    cli
    lgdt    (GDTdescriptor)
    mov     %cr0,%eax
    or      $0x1,%ax
    mov     %eax,%cr0
    jmp     $8,$init_protected
    ret


.code32

init_protected:
    mov     $0x10,%ax
    mov     %ax,%ds
    mov     %ax,%es
    mov     %ax,%fs
    mov     %ax,%gs
    mov     %ax,%ss
    movl    $STACKPOINTER_TOP, %eax
    mov     %eax,%esp
    call    main

.global kernles_place_in_memory
.equ kernles_place_in_memory, 0x100000

main:
    call    Init_interrupts
    call    load_kernel
    cli
    jmp     kernles_place_in_memory
    jmp .







