#include "memory_management.h"
#include "initialize_memory.h"

void generate_reference_num(int size, int required_bytes, char *allocation_number, char *allocation_number_helper)
    {
        int i=0;
        for(i; i < required_bytes; i++)
        {
            if(size >= 8)
                {
                    allocation_number[i] = 0xFF;
                }
            else
                {
                    int i2 = 0;
                    allocation_number[i] = 0;
                    for(i2; i2 < size; i2++)
                        {
                            allocation_number[i] <<= 1;
                            allocation_number[i] |= 1;
                        }
                }
            allocation_number_helper[i] = allocation_number[i];
            size -= 8;
        }
    }

int compare_with_reference(int required_bytes, char *reference, char *allocation_indicator)
    {
        int i;
        for(i = 0; i < required_bytes; i++)
            {
                if((reference[i] & allocation_indicator[i]) != 0)
                    {
                        return 0;
                    }
            }
        return 1;
    }

int find_out_if_data_can_fit_to_this_section(int required_bytes, int *begining_of_appropriate_area, char *reference, char *allocation_indicator)
{
    int i;
    for(i = 0; i < 8; i++)
        {
            if(compare_with_reference(required_bytes, reference, allocation_indicator))
                {
                    return 1;
                }
            else
                {
                    reference[required_bytes - 1] <<= 1;
                    if(reference[required_bytes - 2] & 128)
                        {
                            reference[required_bytes - 1] |= 1;
                        }
                    reference[0] <<= 1;
                    (*begining_of_appropriate_area)++;
                }
        }
    return 0;
}

void* kmalloc(int s)
{
    int size = (s >> 2); //making 4 byte value of size
    if(s % 4)
        size++;
    int help = (size >> 3) + 1;
    if(size % 8)
        help++;
    const int required_bytes = help;
    char allocation_number[required_bytes];
    char allocation_number_helper[required_bytes];
    generate_reference_num(size, required_bytes, allocation_number, allocation_number_helper);
    char *allocation_indicator = (char*)start_of_kernel_data;
    int begining_of_appropriate_area = 0;
    int rangehelper = kernel_data_allocation_flags_size - required_bytes;
    int i;
    int first_check = 0;
    for(i = 0; i < rangehelper; i++)
        {
            if(find_out_if_data_can_fit_to_this_section(required_bytes, &begining_of_appropriate_area, allocation_number_helper, allocation_indicator))
                {
                    first_check = 1;
                    break;
                }
            else
                {
                    int j;
                    for(j = 0; j < required_bytes; j++)
                        {
                            allocation_number_helper[j] = allocation_number[j];
                        }
                    allocation_indicator++;
                }
        }
    if(first_check)
        {
            for(i = 0; i < required_bytes; i++)
                {
                    allocation_indicator[i] |= allocation_number_helper[i];
                }
            return (void*)(start_of_kernel_data + kernel_data_allocation_flags_size + (begining_of_appropriate_area << 2));
        }
    else
        {
            return NULL;
        }
}




