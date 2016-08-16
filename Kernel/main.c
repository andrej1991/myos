#include "./IO/VGA_text_mode/print.h"
#include "./IO/basic_io.h"
#include "./Memory/initialize_memory.h"
#include "./Memory/memory_management.h"


int main()
{

    long long int *gdt_base = get_gdt_base();
    char *allocation_indicator = (char*)start_of_kernel_data;
    printlong(&gdt_base[0]);
    printlong(&gdt_base[1]);
    printlong(&gdt_base[2]);
    int *p1 = kmalloc(33);
    int *p2 = kmalloc(32);
    int *p3 = kmalloc(4);
    int *p4 = kmalloc(4);
    printint(allocation_indicator[0]);
    printint(allocation_indicator[1]);
    printint(allocation_indicator[2]);
    printint(allocation_indicator[3]);
    kfree(p3, 4);
    printint(allocation_indicator[0]);
    printint(allocation_indicator[1]);
    printint(allocation_indicator[2]);
    printint(allocation_indicator[3]);
    printstr("hello world!!!\0");
    __asm__("jmp .");
}
