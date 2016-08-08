.code32

.text
no_hit:
    .asciz  "The file or directory cannot be found\n"

.equ temp_dir_descriptor, 0x500

rootdir_size:
    .int 0
.equ rootdir_loc_in_memory_load_rootdir, 16
.equ rootdir_loc_on_disk, -4
.equ sectors_place_in_memory, -8
.global load_rootdir
.type load_rootdir, @function
load_rootdir:
/*argument: the requiered location of the file in the memory
  return value: the size of the rootdir in bytes*/
    push    %ebp
    push    %ebx
    push    %ecx
    mov     %esp, %ebp
    sub     $8, %esp
    movl    rootdir_loc_in_memory_load_rootdir(%ebp), %eax
    movl    $156, %ebx
    addl    %eax, %ebx
    push    %eax
    pushl   $0x10
    call    read_atapi
    movl    %ds:10(%ebx), %ecx
    mov     %ecx, rootdir_size
    shrl    $11, %ecx
    movl    rootdir_loc_in_memory_load_rootdir(%ebp), %eax
    movl    %eax, sectors_place_in_memory(%ebp)
    movl    %ds:2(%ebx), %eax
    movl    %eax, rootdir_loc_on_disk(%ebp)
    reading_in_the_rootdir:
        movl    sectors_place_in_memory(%ebp), %eax
        push    %eax
        movl    rootdir_loc_on_disk(%ebp), %eax
        push    %eax
        call    read_atapi
        subl    $1, %ecx
        jz      return_from_load_rootdir
        addl    $0x800, sectors_place_in_memory(%ebp)
        addl    $1, rootdir_loc_on_disk(%ebp)
        jmp     reading_in_the_rootdir
    return_from_load_rootdir:
    mov     rootdir_size, %eax
    mov     %ebp, %esp
    pop     %ecx
    pop     %ebx
    pop     %ebp
    ret

fileloc:
    .int 0
filesize:
    .int 0
.equ current_dirs_size, 44
.equ file_to_find, 40
.equ rootdir_loc_find_file_dir, 36
.equ direntry_begining, -4
.equ direntry_dirname, -8
.global find_file_dir
.type find_file_dir, @function
find_file_dir:
/*first push the size of the directory file
  then push the memorylocation of the files or directories name (in string format) what you want to find
  finally push the location (int the memory) of the directory what you want to search;
  the directory descriptor needs to be loaded to the memoy when calling the function
  return values: the location of the file on the disk -> in eax
                 the size of the file -> in edi*/
    pusha
    mov     %esp, %ebp
    sub     $12, %esp
    mov     rootdir_loc_find_file_dir(%ebp), %eax
    mov     %eax, direntry_begining(%ebp)
    add     $33, %eax
    mov     %eax, direntry_dirname(%ebp)
    xor     %eax, %eax
    mov     current_dirs_size(%ebp), %ecx
    finding_the_direntry:
        add     %eax, direntry_begining(%ebp)
        add     %eax, direntry_dirname(%ebp)
        movl    file_to_find(%ebp), %eax
        push    %eax
        movl    direntry_dirname(%ebp), %eax
        push    %eax
        call    strcmp
        cmp     $1, %eax
        jz      return_from_find_file_dir
        movl    direntry_begining(%ebp), %ebx
        xor     %eax, %eax
        movb    %ds:(%ebx), %al
        cmpb    $0, %al
        jz      no_hit_found_find_file_dir
        sub     %eax, %ecx
        cmp     $0, %ecx
        jle     no_hit_found_find_file_dir
        jmp     finding_the_direntry
    return_from_find_file_dir:
    movl    direntry_begining(%ebp), %ebx
    movl    %ds:2(%ebx), %eax
    movl    %eax, fileloc
    movl    %ds:10(%ebx), %eax
    movl    %eax, filesize
    mov     %ebp, %esp
    popa
    movl    fileloc, %eax
    movl    filesize, %edi
    ret
    no_hit_found_find_file_dir:
    lea     no_hit, %eax
    push    %eax
    call    printstr
    mov     %ebp, %esp
    popa
    mov     $0, %eax
    mov     $0, %edi
    ret
    
    #returning with the filesize is not done yet

.equ source, 20
.equ destination, 16
.type strcmp, @function
strcmp:
    push    %ebx
    push    %esi
    push    %ebp
    mov     %esp, %ebp
    movl    source(%ebp), %esi
    movl    destination(%ebp), %ebx
    begining_of_the_loop:
        movb    %ds:(%ebx), %ah
        movb    (%esi), %al
        cmpb    $0x0, %al
        jz      return_OK_from_strcmp
        cmpb    %al, %ah
        jz      continue_on_loop
        movl    $0x0, %eax
        jmp     return_from_strcmp
        continue_on_loop:
        inc     %esi
        inc     %ebx
        jmp     begining_of_the_loop
    return_OK_from_strcmp:
    movl    $0x1, %eax
    return_from_strcmp:
    mov     %ebp, %esp
    pop     %ebp
    pop     %esi
    pop     %ebx
    ret

kernel_dir:
    .asciz  "KERNEL"
kernel_bin:
    .asciz  "KERNEL.BIN"

.equ directories_place_in_mem, -4
.global load_kernel
.type load_kernel, @function
load_kernel:
    push    %ebp
    mov     %esp, %ebp
    subl    $8, %esp
    push    $temp_dir_descriptor
    call    load_rootdir
    push    %eax
    lea     kernel_dir, %eax
    push    %eax
    push    $temp_dir_descriptor
    call    find_file_dir
    mov     $temp_dir_descriptor, %ebx
    mov     %eax, %edx
    mov     %edi, %ecx
    shrl    $11, %ecx
    load_kernel_dir:
        push    %ebx
        push    %edx
        call    read_atapi
        add     $0x800, %ebx
        inc     %edx
        loop    load_kernel_dir
    push    %edi
    lea     kernel_bin, %eax
    push    %eax
    pushl   $temp_dir_descriptor
    call    find_file_dir
    push    %edi
    call    store_kernel_size
    xchg    %eax, %edi
    xor     %edx, %edx
    movl    $0x800, %ecx
    divl    %ecx
    cmp     $0, %edx
    jz      do_not_inc
    inc     %eax
    do_not_inc:
    # kernles_place_in_memory is a global constant defined in boot.s
    mov     $kernles_place_in_memory, %ebx
    mov     %edi, %edx
    mov     %eax, %ecx
    load_kernel_bin:
        push    %ebx
        push    %edx
        call    read_atapi
        add     $0x800, %ebx
        inc     %edx
        loop    load_kernel_bin
    mov     %ebp, %esp
    pop     %ebp
    ret

.type store_kernel_size, @function
store_kernel_size:
    pusha
    mov     %esp, %ebp
    mov     36(%ebp), %ecx
    #it is a memory location intentionally
    movl    0x40100, %eax
    mov     $28, %ebx
    mulw    %bx
    shll    $16, %edx
    andl    $0xffff0000, %edx
    orl     %edx, %eax
    addl    $0x40104, %eax
    mov     %eax, %ebx
    mov     %ecx, (%ebx)
    popa
    ret






