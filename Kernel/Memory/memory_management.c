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

int get_required_bytes(int size, int *indicator_bit_count)
{
    *indicator_bit_count = (size >> 2); //making 4 byte value of size
    if(size % 4)
        (*indicator_bit_count)++;
    int help = (*indicator_bit_count >> 3) + 1;
    if(*indicator_bit_count % 8)
        help++;
    return help;
}

void* kmalloc(int size)
{
    int indicator_bit_count;
    const int required_bytes = get_required_bytes(size, &indicator_bit_count);
    char allocation_number[required_bytes];
    char allocation_number_helper[required_bytes];
    generate_reference_num(indicator_bit_count, required_bytes, allocation_number, allocation_number_helper);
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

int kfree(void *p, int size)
{
    /*if((int)p % 4)
        {
            printstr("returning\n");
            return 0;
        }*/
    int indicator_bit_count;
    int required_bytes = get_required_bytes(size, &indicator_bit_count);
    char *allocation_indicator = (char*)start_of_kernel_data;
    char allocation_number[required_bytes];
    int begining_of_appropriate_area = ((int)p - start_of_kernel_data - kernel_data_allocation_flags_size) >> 2;
    int i;
    for(i = 1; i < (required_bytes -1); i++)
        {
            allocation_number[i] = 0;
        }
    allocation_number[0] = allocation_number[required_bytes - 1] = 0xFF;
    int bitlimit = 8;
    int start = begining_of_appropriate_area % 8;
    if((start + indicator_bit_count) < 8)
        bitlimit = start + indicator_bit_count;
    char sample[8] = {0xFE, 0xFD, 0xFB, 0xF7, 0xEF, 0xDF, 0xBF, 0x7F};
    for(i = start; i < bitlimit; i++)
        {
            allocation_number[0] &= sample[i];
        }
    bitlimit = bitlimit - start + (required_bytes)*8;
    if(bitlimit < indicator_bit_count)
        {
            allocation_number[required_bytes - 1] <<= (indicator_bit_count - bitlimit);
        }
    int starting_byte = begining_of_appropriate_area >> 3;
    printint(starting_byte);
    for(i = 0; i < required_bytes; i++)
        {
            allocation_indicator[starting_byte + i] &= allocation_number[i];
        }
    return 1;
}




