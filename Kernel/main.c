#include "./IO/VGA_text_mode/print.h"
#include "./IO/basic_io.h"
#include "./Memory/initialize_memory.h"


int main()
{
    struct GDT_access_byte acc;
    acc.present_bit = 1;
    acc.privilege_level = 0;
    acc.descriptor_type = 1;
    acc.executable_bit = 1;
    acc.direction_bit = 0;
    acc.read_write = 1;
    acc.accessed_bit = 0;
    int i = create_gdt_access_byte(&acc);
    printint(i);
    int kernel_size = get_normalized_kernel_size();
    long long int *gdt_base = get_gdt_base();
    printlong(&gdt_base[0]);
    printlong(&gdt_base[1]);
    printlong(&gdt_base[2]);
    printstr("hello world!!!\0");
    __asm__("jmp .");
}
