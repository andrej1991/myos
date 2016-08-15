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
    int *p1 = kmalloc(33);
    int *p2 = kmalloc(32);
    int *p3 = kmalloc(4);
    int *p4 = kmalloc(4);
    printint(p1);
    printint(p2);
    printint(p3);
    printint(p4);
    printstr("hello world!!!\0");
    __asm__("jmp .");
}
