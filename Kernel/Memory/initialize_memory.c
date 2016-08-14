#include "initialize_memory.h"
#include "../IO/VGA_text_mode/print.h"

int start_of_kernel_data = 0;
int kernel_data_allocation_flags_size = 0;

int get_actual_kernel_size()
{
    int listsize = *((int*)AddressRangeDescriptor_arraysize_location);
    int kernel_size = *((int*)(28*listsize + AddressRangeDescriptor_arraybase));
    return kernel_size;
}

int get_normalized_kernel_size()
{
    int act_size = get_actual_kernel_size();
    int norm_size = 0;
    if((act_size % 0x1000) == 0)
        {
            norm_size = act_size;
        }
    else
        {
            norm_size = (int)(act_size / 0x1000 + 1) * 0x1000;
        }
    return norm_size;
}

void load_gdt_descriptor(long long int *entry_loc, struct GDTdescriptor *descriptor)
{
    char *helper = entry_loc;
    helper[0] = descriptor->limit & 0xfffff;
    helper[1] = descriptor->limit >> 8;
    helper[2] = descriptor->base;
    helper[3] = descriptor->base >> 8;
    helper[4] = descriptor->base >> 16;
    helper[5] = descriptor->access_byte;
    helper[6] = descriptor->limit >> 16;
    helper[7] = descriptor->base >> 24;
    if(descriptor->granuality_flag)
        {
            helper[6] |= 128;
        }
    if(descriptor->size_flag)
        {
            helper[6] |= 64;
        }
}

char create_gdt_access_byte(struct GDT_access_byte *accessb)
{
    char access_byte = 0;
    if(! accessb->present_bit)
        {
            printstr("present bit must be 1 for all valid descriptors\n\0");
        }
    access_byte |= 1 << 7;
    access_byte |= (accessb->privilege_level & 0x3) << 5;
    if(! accessb->descriptor_type)
        {
            printstr("descriptor type cannot be system descriptor, setting it to code/data\n\0");
        }
    access_byte |= 1 << 4;
    if(accessb->executable_bit)
        {
            access_byte |= 1 << 3;
        }
    if(accessb->direction_bit)
        {
            access_byte |= 1 << 2;
        }
   if(accessb->read_write)
        {
            access_byte |= 1 << 1;
        }
    if(accessb->accessed_bit)
        {
            printstr("the accessed bit can be left 0\n\0");
        }
    return access_byte;
}

void print_meminfo(int type)
{
/*prints memory information returned by BIOS call 0x15 eax = 0xE820; which was called from the bootloader*/
    int listsize = *((int*)AddressRangeDescriptor_arraysize_location);
    struct AddressRangeDescriptor *desc = AddressRangeDescriptor_arraybase;
    int i=0;
    for(i; i<listsize; i++)
        {
            if((desc[i].type == type) || (type == -1))
                {
                    printlong(&(desc[i].base_address));
                    printlong(&(desc[i].length));
                    printint(desc[i].type);
                    printstr("----------------\n\0");
                }
        }
}

void initialize_kernel_data_area()
{
    int kernel_data_size = size_of_kernel_data_area + 0x100000 - start_of_kernel_data;
    kernel_data_allocation_flags_size = kernel_data_size / 33;
    int lim = (kernel_data_allocation_flags_size >> 2) + 1;
    int i = 0;
    int *base = start_of_kernel_data;
    for(i; i <= lim; i++)
        {
            base[i] = 0;
        }
}

int initialize_memory()
{
    int kernel_size = get_normalized_kernel_size();
    int listsize = *((int*)AddressRangeDescriptor_arraysize_location);
    int usable_ram[listsize];
    struct AddressRangeDescriptor *desc = AddressRangeDescriptor_arraybase;
    long long int *gdt_base = get_gdt_base();
    int i, count_of_usable_ram_chunks = 0;
    int limit;
    for(i = 0; i < listsize; i++)
        {
            if(desc[i].type == 1)
                {
                    usable_ram[count_of_usable_ram_chunks] = i;
                    count_of_usable_ram_chunks++;
                }
        }
    limit = (desc[usable_ram[count_of_usable_ram_chunks-1]].base_address + desc[usable_ram[count_of_usable_ram_chunks-1]].length) >> 12;
    if((desc[usable_ram[0]].length + desc[usable_ram[0]].base_address) > 0x100000)
        {
            printstr("ERROR: the 0th usable RAM chunk is bigger than 1MB\0");
            asm("jmp    .");
        }
    for(i = 1; i < count_of_usable_ram_chunks; i++)
        {
            if((desc[usable_ram[i]].base_address <= 0x100000) && ((desc[usable_ram[i]].base_address + desc[usable_ram[i]].length) > 0x100000))
                break;
        }
    if((desc[usable_ram[i]].base_address - 0x100000 + desc[usable_ram[i]].length) < (kernel_size + size_of_kernel_data_area))
        {
            printstr("ERROR: not enough room for the kernel in the memory\0");
            asm("jmp    .");
        }
    else
        {
            start_of_kernel_data = 0x100000 + kernel_size + size_of_gdt + size_of_idt;
            create_protected_flat_model(gdt_base, limit);
            initialize_kernel_data_area();
        }
    return 3;
}

void create_protected_flat_model(long long int *gdt_base, int limit)
{
    char access_byte;
    struct GDTdescriptor gdt_desc;
    gdt_desc.base = 0;
    gdt_desc.limit = 0;
    gdt_desc.granuality_flag = 0;
    gdt_desc.size_flag = 0;
    gdt_desc.access_byte = 0;
    struct GDT_access_byte acc;
    acc.present_bit = 1;
    acc.privilege_level = 0;
    acc.descriptor_type = 1;
    acc.executable_bit = 1;
    acc.direction_bit = 0;
    acc.read_write = 1;
    acc.accessed_bit = 0;
    //mandatory zero-descriptor
    load_gdt_descriptor(gdt_base, &gdt_desc);
    gdt_base++;
    //kernel code descriptor
    gdt_desc.limit = limit;
    gdt_desc.granuality_flag = 1;
    gdt_desc.size_flag = 1;
    gdt_desc.access_byte = create_gdt_access_byte(&acc);
    load_gdt_descriptor(gdt_base, &gdt_desc);
    gdt_base++;
    //kernel data descriptor
    acc.executable_bit = 0;
    gdt_desc.access_byte = create_gdt_access_byte(&acc);
    load_gdt_descriptor(gdt_base, &gdt_desc);
    gdt_base++;
}

long long int* get_gdt_base()
{
    return (long long int*)(0x100000 + get_normalized_kernel_size());
}





