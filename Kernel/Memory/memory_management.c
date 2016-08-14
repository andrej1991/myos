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
        //int debug1, debug2;
        for(i = 0; i < required_bytes; i++)
            {
                if((reference[i] & allocation_indicator[i]) != 0)
                    {
                        /*debug1=allocation_indicator[0];
                        printint(debug1);
                        debug1=allocation_indicator[1];
                        printint(debug1);
                        debug2=reference[0];
                        printint(debug2);
                        debug2=reference[1];
                        printint(debug2);*/
                        return 0;
                    }
            }
        return 1;
    }

int find_out_if_data_can_fit_to_this_section(int required_bytes, int *begining_of_appropriate_area, char *reference, char *used_indicator)
{
    int i;
    for(i = 0; i < 8; i++)
        {
            if(compare_with_reference(required_bytes, reference, used_indicator))
                {
                    return 1;
                }
            else
                {
                    reference[0] <<= 1;
                    reference[required_bytes - 1] <<= 1;
                    if(reference[required_bytes - 2] & 128)
                        {
                            reference[required_bytes - 1] |= 1;
                        }
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
    char *used_indicator = start_of_kernel_data;
    used_indicator[0] = 31;
    used_indicator[1] = 1;
    int begining_of_appropriate_area = 0;
    int rangehelper = kernel_data_allocation_flags_size - required_bytes;
    int i;
    int first_check = 0;
    for(i = 0; i < rangehelper; i++)
        {
            if(find_out_if_data_can_fit_to_this_section(required_bytes, &begining_of_appropriate_area, allocation_number_helper, used_indicator))
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
                    used_indicator++;
                }
        }
    printint(size);
    printint(begining_of_appropriate_area);
    if(first_check)
        {
            return (void*)(start_of_kernel_data + kernel_data_allocation_flags_size + (begining_of_appropriate_area << 2));
        }
    else
        {
            return NULL;
        }
}




