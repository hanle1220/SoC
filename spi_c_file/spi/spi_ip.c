/*
 * spi_ip.c
 * Han Le
 */
#include <stdlib.h>          // EXIT_ codes
#include <stdio.h>
#include <stdint.h>          // C99 integer types -- uint32_t
#include <stdbool.h>         // bool
#include <fcntl.h>           // open
#include <sys/mman.h>        // mmap
#include <unistd.h>          // close
#include "../address_map.h"  // address map
#include "spi_ip.h"         // gpio
#include "spi_regs.h"       // registers


//-----------------------------------------------------------------------------
// Global variables
//-----------------------------------------------------------------------------

uint32_t *base = NULL;

//-----------------------------------------------------------------------------
// Subroutines
//-----------------------------------------------------------------------------

bool spiOpen()
{
    // Open /dev/mem
    int file = open("/dev/mem", O_RDWR | O_SYNC);
    bool bOK = (file >= 0);
    if (bOK)
    {
        // Create a map from the physical memory location of
        // /dev/mem at an offset to LW avalon interface
        // with an aperature of SPAN_IN_BYTES bytes
        // to any location in the virtual 32-bit memory space of the process
        base = mmap(NULL, SPAN_IN_BYTES, PROT_READ | PROT_WRITE, MAP_SHARED,
                    file, LW_BRIDGE_BASE + SPI_BASE_OFFSET);
        bOK = (base != MAP_FAILED);

        // Close /dev/mem
        close(file);
    }
    return bOK;
}

void setSpiData(uint32_t value)
{
    *(base + OFS_DATA) = value;
}

uint32_t getSpiData()
{
    uint32_t value = *(base + OFS_DATA);
    if(value == 0) return -1;
    return value;
}

void setSpiWordSize(uint16_t size)
{
    *(base + OFS_CONTROL) |= size << 0;
}

void selectAutoMode(uint8_t cs)
{
    *(base + OFS_CONTROL) |= 32 << cs;
}

void selectManualMode(uint8_t cs)
{
    *(base + OFS_CONTROL) &= ~(32 << cs);
}

void enableCS(uint8_t cs)
{
    *(base + OFS_CONTROL) |= 0x200 << cs;
}

void disableCS(uint8_t cs)
{
    *(base + OFS_CONTROL) &= ~(0x200 << cs);
}

void selectCS(uint8_t cs)
{
    *(base + OFS_CONTROL) |= cs << 13;
}

void enableSpi()
{
    *(base + OFS_CONTROL) |= 1 << 15;
}

void disableSpi()
{
    *(base + OFS_CONTROL) &= ~(1 << 15);
}

void setSpiMode(uint8_t cs, uint8_t value)
{
    if(cs == 0) *(base + OFS_CONTROL) |= value << 16;
    if(cs == 1) *(base + OFS_CONTROL) |= value << 18;
    if(cs == 2) *(base + OFS_CONTROL) |= value << 20;
    if(cs == 3) *(base + OFS_CONTROL) |= value << 22;
}

void setSpiBaudRate(uint32_t baudRate)
{
    uint32_t mask = ((50000000 / 2) / baudRate) << 7;
    *(base + OFS_BRD) |= mask;
}
