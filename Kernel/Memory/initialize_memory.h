#ifndef INITIALIZE_MEMORY_H_INCLUDED
#define INITIALIZE_MEMORY_H_INCLUDED

#define AddressRangeDescriptor_arraysize_location 0x40100
#define AddressRangeDescriptor_arraybase 0x40104
#define size_of_kernel_data_area 0x421000
#define kernel_heap_size 0x400000
#define size_of_gdt 0x10000
#define size_of_idt 0x1000
#define kernel_stack_size 0x10000

#define unused 0
#define kernel_code 1
#define kernel_dat 2
#define kernel_stack 3
#define app_code 4
#define app_data 5
#define app_stack 6
#define gdt_descriptor 7
#define idt_descriptor 8

struct AddressRangeDescriptor{
    long long int base_address;
    long long int length;
    int type;
    int ACPI3_0__extended_bitfield;
    int descriptor_size;
}AddressRangeDescriptor;

struct GDT_access_byte{
    char present_bit;
    char privilege_level;
    char descriptor_type;
    char executable_bit;
    char direction_bit;
    char read_write;
    char accessed_bit;
}GDT_access_byte;

struct GDTdescriptor{
    int base;
    int limit;
    char granuality_flag;
    char size_flag;
    char access_byte;
}GDTdescriptor;

int get_actual_kernel_size();
int get_normalized_kernel_size();
void load_gdt_descriptor(long long int *entry_loc, struct GDTdescriptor *descriptor);
void print_meminfo(int);
char create_gdt_access_byte(struct GDT_access_byte *accessb);
int create_base_gdt(char *gdt_descriptor_identifier);
int* get_gdt_base();

#endif
