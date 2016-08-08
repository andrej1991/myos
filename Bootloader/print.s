.code32
.text

    pos:            ################################ pos=sor * oszlop (pos_max=80*25=2000)
        .int 0  ################################    egy sorban 80 oszlop van; a képernyőn pedig 25 sor
    CharAttrib:
        .byte 0x02

.equ    default_CharAttrib, 0x02
.equ    highlighted, 0x04
.equ    video_memory, 0xb8000

.global iowait
.type iowait, @function
iowait:
    #csak a régebbi rendszerekben kell, ahol az I/O parancsok lassúak voltak
    push    %eax
    push    %edx
    mov     $0,%al
    mov     $0x80,%dx
    out     %al,%dx
    pop     %edx
    pop     %eax
    ret

.global printstr
.type printstr, @function
printstr:
    push    %ebp
    push    %eax
    push    %esi
    mov     %esp,%ebp
    movl    16(%ebp),%esi
    writestr:
    Xor     %eax,%eax
    lodsb
    orb     %al,%al
    jz      endOfString
    push    %eax
    call    printchar
    jmp     writestr
    endOfString:
    #call    move_cursor
    mov     %ebp,%esp
    pop     %esi
    pop     %eax
    pop     %ebp
    ret

.global printchar
.type printchar, @function
printchar:
    pusha
    mov     %esp,%ebp
    mov     $video_memory,%ebx
    xor     %edx,%edx
    mov     pos,%eax
    shl     $1,%eax
    add     %eax,%ebx
    movl    36(%ebp),%edx
    cmpb    $10,%dl
    jnz     it_was_not_new_line
        movl    pos,%eax
        mov     $80,%ecx
        divb    %cl
        subb    %ah,%cl
        and     $0x000000ff,%ecx
        add     %ecx,pos
        jmp     display_management
    it_was_not_new_line:
    movb    %dl,(%ebx)
    inc     %ebx
    movb    CharAttrib,%al
    movb    %al,(%ebx)
    incl    pos
    display_management:
    cmpl    $2000,pos
    jnz     endofprintchar
    movl    $0,pos
    endofprintchar:
    mov     %ebp,%esp
    popa
    ret

/*.global printreg
.type printreg, @function
printreg:
    #push   %ebp
    pusha
    movl    %esp,%ebp
    movl    $4,%ecx
    xor     %ebx,%ebx
    movl    36(%ebp),%eax
    start_printing:
    roll    $8,%eax
    movb    %al,%bl
    shrb    $4,%bl
    call    printNible
    movb    %al,%bl
    andb    $0x0f,%bl
    call    printNible
    loop    start_printing
    push    $10
    call    printchar
    mov     %ebp,%esp
    popa
    #pop    %ebp
    ret

printNible:
    cmpb    $0xA,%bl
    jl      lessthen_0xA
    addb    $0x37,%bl
    push    %ebx
    call    printchar
    pop     %ebx        #### csak azért, hogy a returnnál jól működjön
    ret
    lessthen_0xA:
    addb    $0x30,%bl
    push    %ebx
    call    printchar
    pop     %ebx        #### csak azért, hogy a returnnál jól működjön
    ret

move_cursor:
    push    %ecx
    push    %eax
    push    %edx
    mov     pos,%ecx
    #inc    %ecx
    movb    $0x0f,%al
    movw    $0x3d4,%dx
    out     %al,%dx
    call    iowait

    mov     %ecx,%eax
    movw    $0x3d5,%dx
    out     %al,%dx
    call    iowait

    movb    $0x0e,%al
    movw    $0x3d4,%dx
    out     %al,%dx
    call    iowait

    mov     %ecx,%eax
    shrw    $8,%ax
    movw    $0x3d5,%dx
    out     %al,%dx
    call    iowait

    pop     %edx
    pop     %eax
    pop     %ecx
    ret*/

