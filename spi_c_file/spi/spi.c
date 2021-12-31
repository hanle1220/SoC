/*
 * spi.c
 * Han Le
 */

#include <stdlib.h>          // EXIT_ codes
#include <stdio.h>           // printf
#include <stdint.h>
#include <stdbool.h>
#include "spi_ip.h"         // GPIO IP library

int main(int argc, char* argv[])
{
    uint8_t value, device;
    uint32_t data, lastValue = 0;
    if(argc == 2)
    {
        spiOpen();
        if(strcmp(argv[1], "rx_data") == 0)
        {
            printf("Value in RX_FIFO\n%d\n",getSpiData());
        }
        else
            printf("Invalid!\n");
    }
    if(argc == 3)
    {
        spiOpen();
        if(strcmp(argv[1], "baud_rate") == 0)
        {
            data = atoi(argv[2]);
            setSpiBaudRate(data);
            printf("Last written Value = %d\n", lastValue);
            lastValue = data;
        }
        else if(strcmp(argv[1], "word_size") == 0)
        {
            data = (uint16_t)atoi(argv[2]);
            sestSpiWordSize(data);
            printf("Last written Value = %d\n", lastValue);
            lastValue = data;
        }
        else if(strcmp(argv[1], "cs_select") == 0)
        {
            value = atoi(argv[2]);
            selectCS(value);
            printf("Last written Value = %d\n", lastValue);
            lastValue = value;
        }
        else if(strcmp(argv[1], "tx_data") == 0)
        {
            data = atoi(argv[2]);
            setSpiData(data);
        }
        else
            printf("Invalid!\n");
    }
    else if(argc == 4)
    {
        spiOpen();
        device = atoi(argv[1]);
        value = atoi(argv[3]);
        if(strcmp(argv[2], "mode") == 0)
        {
            setSpiMode(device, value);
            printf("Last written Value = %d\n", lastValue);
            lastValue = value;
        }
        else if(strcmp(argv[2], "cs_auto") == 0)
        {
            if(strcmp(argv[3], "true") == 0)
            {
                selectAutoMode(device);
                printf("Last written Value = %d\n", lastValue);
                lastValue = 1;
            }
            else if (strcmp(argv[3], "false") == 0)
            {
                selectManualMode(device);
                printf("Last written Value = %d\n", lastValue);
                lastValue = 0;
            }
            else
            {
                printf("Invalid!\n");
                return EXIT_FAILURE;
            }
        }
        else if(strcmp(argv[2], "cs_enable") == 0)
        {
            if(strcmp(argv[3], "true") == 0)
            {
                enableCS(device);
                printf("Last written Value = %d\n", lastValue);
                lastValue = 1;
            }
            else if (strcmp(argv[3], "false") == 0)
            {
                disableCS(device);
                printf("Last written Value = %d\n", lastValue);
                lastValue = 0;
            }
            else
            {
                printf("Invalid!\n");
                return EXIT_FAILURE;
            }
        }
    }
    else
    {
        printf("Invalid!\n");
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}

