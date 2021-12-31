/*
 * spi_expander.c
 * Han Le
 */

#include <stdlib.h>          // EXIT_ codes
#include <stdio.h>           // printf
#include "spi_ip.h"         // GPIO IP library

int main(int argc, char* argv[])
{
    uint8_t pin;

    if(argc == 4)
    {
        spiOpen();
        pin = atoi(argv[1]);
        if(strcmp(argv[2], "dir") == 0)
            //write direction of port pin
            //read last written value
        else if(strcmp(argv[2], "pull up") == 0)
            //write pull up conntrol on port input
            //read last written value
        else if(strcmp(argv[2], "data") == 0)
            //write data on port output
            //read data on port pin
    }
    else
    {
        printf("Invalid!\n");
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}



