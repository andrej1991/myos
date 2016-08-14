#include "./IO/VGA_text_mode/print.h"
#include "./IO/basic_io.h"
#include "./Memory/initialize_memory.h"
#include "./Memory/memory_management.h"


int main()
{

    long long int *gdt_base = get_gdt_base();
    printlong(&gdt_base[0]);
    printlong(&gdt_base[1]);
    printlong(&gdt_base[2]);
    initialize_kernel_data_area();
    kmalloc(14);
    printstr("hello world!!!\0");
    __asm__("jmp .");
}
