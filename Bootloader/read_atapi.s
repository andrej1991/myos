.code32

.text

.equ ATA_DATA, 0x1F0
.equ ATA_FEATURES, 0x1F1
.equ ATA_SECTOR_COUNT, 0x1F2
.equ ATA_ADDRESS1, 0x1F3
.equ ATA_ADDRESS2, 0x1F4
.equ ATA_ADDRESS3, 0x1F5
.equ ATA_DRIVE_SELECT, 0x1F6
.equ ATA_COMMAND, 0x1F7
.equ ATA_DCR, 0x3F6

.macro wait_400_ns
    push    %edx
    push    %eax
    movw    $ATA_DRIVE_SELECT,%dx
    inb     %dx,%al
    inb     %dx,%al
    inb     %dx,%al
    inb     %dx,%al
    pop     %eax
    pop     %edx
.endm

.macro inbyte from
    movw    \from, %dx
    inb     %dx, %al
.endm

.macro inword from
    movw    \from, %dx
    inw     %dx, %ax
.endm

.macro outbyte what, where
    movw    \where, %dx
    movb    \what, %al
    outb    %al, %dx
.endm

.macro outword what, where
    movw    \where, %dx
    movw    \what, %ax
    outw    %ax, %dx
.endm


/* valid values for "bus" 
define ATA_BUS_PRIMARY     0x1F0
define ATA_BUS_SECONDARY   0x170
valid values for "drive"
ATA_DRIVE_MASTER    0xA0
ATA_DRIVE_SLAVE     0xB0*/

.global cd_dvd_interrupt_happened
cd_dvd_interrupt_happened:
    .byte 0


#to call the function first push the buffer then the sector lba
.equ buffer, 40
.equ sector_to_read, 36
.global read_atapi
.type read_atapi, @function
read_atapi:
    pusha
    mov     %esp,%ebp
    movl    sector_to_read(%ebp), %edi
    #ATA_DRIVE_MASTER & (1<<4) // 0xA0&(1<<4)
    outbyte $0x00, $ATA_DRIVE_SELECT
    wait_400_ns
    xor     %eax, %eax
    wait_for_drive_to_be_ready_00:
        inbyte  $ATA_COMMAND
        andb    $64, %al
        jz      wait_for_drive_to_be_ready_00
    outbyte $0x0, $ATA_FEATURES
    #atapi sector size (2048) & 0xff
    outbyte $0x0, $ATA_ADDRESS2
    #atapi sector size (2048) >> 8
    outbyte $0x8, $ATA_ADDRESS3
    #ATA packet command
    outbyte $0xA0, $ATA_COMMAND
    wait_while_ide_is_busy:
        inbyte $ATA_COMMAND
        andb    $0x80, %al
        jnz     wait_while_ide_is_busy
    xor     %eax, %eax
    #while (!((status = inb (ATA_COMMAND (bus))) & 0x8) && !(status & 0x1))
    wait_ide_to_be_ready:
        inbyte $ATA_COMMAND
        mov     %eax, %ebx
        andb    $0x08, %bl
        notb    %bl
        andb    $0x01, %al
        notb    %al
        cmpb    $0x0, %bl
        jz      wait_ide_to_be_ready
        cmpb    $0x0, %al
        jz      wait_ide_to_be_ready
    xor     %ebx, %ebx
    outword $0x04a8, $ATA_DATA
    #sending bites 16-31 of the sectror what needs to be readed
    movl    %edi, %eax
    shl     $16, %eax
    xchgb   %al,%ah
    outword %ax, $ATA_DATA
    #sending bites 0-15 of the sectror what needs to be readed
    movl    %edi, %eax
    xchgb   %al,%ah
    andl    $0xffff,%eax
    outword %ax, $ATA_DATA
    outword $0x0000, $ATA_DATA
    outword $0x0100, $ATA_DATA
    outword $0x0000, $ATA_DATA
    call    schedule
    inbyte  $ATA_ADDRESS3
    mov     %eax, %ecx
    shl     $8, %ecx
    inbyte  $ATA_ADDRESS2
    andl    $0xff, %eax
    or      %eax, %ecx
    movl    $0x800, %ecx
    mov     buffer(%ebp),%ebx
    read_the_sector:
        inword      $ATA_DATA
        movw        %ax, %ds:(%ebx)
        add         $0x2, %ebx
        loop        read_the_sector
    call    schedule
    mov     %ebp,%esp
    popa
    ret

schedule:
    push    %eax
    wait_for_interrupt:
        movb    cd_dvd_interrupt_happened, %al
        cmpb    $1, %al
        jnz     wait_for_interrupt
    movb    $0, cd_dvd_interrupt_happened
    pop     %eax
    ret

/*.global reset_atapi
.type reset_atapi, @function
reset_atapi:
    push    %ebp
    mov     %esp, %ebp
    xor     %eax, %eax
    inbyte  $ATA_COMMAND
    push    %eax
    call    printreg
    push    $10
    call    printchar
    inbyte  $ATA_FEATURES
    push    %eax
    call    printreg
    push    $10
    call    printchar
    outbyte $0x4, $ATA_DCR
    push    %ecx
    mov     $0xfffffff, %ecx
    wait_atapi_to_reset00:
        nop
    loop    wait_atapi_to_reset00
    push    $65
    call    printchar
    outbyte $0x0, $ATA_DCR
    mov     $0xfffffff, %ecx
    wait_atapi_to_reset01:
        nop
    loop    wait_atapi_to_reset01
    inbyte  $ATA_COMMAND
    inbyte  $ATA_FEATURES
    mov     $0xffffffff, %ecx
    wait_atapi_to_reset02:
        nop
    loop    wait_atapi_to_reset02
    inbyte  $ATA_COMMAND
    push    %eax
    call    printreg
    push    $10
    call    printchar
    mov     %ebp, %esp
    pop     %ebp
    ret

/*.global detecting_packet_device
.type detecting_packet_device, @function
detecting_packet_device:
    push    %ebp
    mov     %esp,%ebp
    #ATA_DRIVE_MASTER & (1<<4) // 0xA0&(1<<4)
    outbyte $0x00, $ATA_DRIVE_SELECT
    xor	%eax, %eax
    wait_for_drive_to_be_ready_01:
        inbyte  $ATA_COMMAND
        andb    $64, %al
        jz      wait_for_drive_to_be_ready_01
    outbyte $0xEC, $ATA_COMMAND
    wait_400_ns
    not_ready_yet_00:
        inbyte  $ATA_COMMAND
        push    %eax
        andb    $0x01, %al
        jnz     detect_dev
        pop     %eax
        andb    $0x08, %al
        jz      not_ready_yet_00
    detect_dev:
    inbyte  $ATA_SECTOR_COUNT
    and     $0xff,%eax
    push    %eax
    call    printreg
    push    $10
    call    printchar
    inbyte  $ATA_ADDRESS1
    and     $0xff,%eax
    push    %eax
    call    printreg
    push    $10
    call    printchar
    inbyte  $ATA_ADDRESS2
    and     $0xff,%eax
    push    %eax
    call    printreg
    push    $10
    call    printchar
    inbyte  $ATA_ADDRESS3
    and     $0xff,%eax
    push    %eax
    call    printreg
    push    $10
    call    printchar
    mov     %ebp,%esp
    pop     %ebp
    ret*/

/*.global identify_packet_device
.type identify_packet_device, @function
identify_packet_device:
    push    %ecx
    push    %edx
    push    %ebp
    mov     %esp,%ebp
    outbyte $0xA1, $ATA_COMMAND
    xxxx:
        inbyte  $ATA_COMMAND
        andb    $0x08, %al
        jz      xxxx
    xor      %eax,%eax
    inword   $ATA_DATA
    push     %eax
    call     printreg
    push     $10
    call     printchar
    mov      $255, %ecx
    #doesn't processes the data yet
    read_identify_data:
        inword  $ATA_DATA
        loop    read_identify_data
    mov     %ebp,%esp
    pop     %ebp
    pop     %edx
    pop     %ecx
    ret*/
