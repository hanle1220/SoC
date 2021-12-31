/*
 * spi_ip.h
 * Han Le
 */

#ifndef SPI_IP_H_
#define SPI_IP_H_

#include <stdint.h>          // C99 integer types -- uint32_t
#include <stdbool.h>         // bool

bool spiOpen();
void setSpiData(uint32_t value);
uint32_t getSpiData();
void setSpiWordSize(uint16_t size);
void selectAutoMode(uint8_t cs);
void selectManualMode(uint8_t cs);
void enableCS(uint8_t cs);
void disableCS(uint8_t cs);
void selectCS(uint8_t cs);
void enableSpi();
void disableSpi();
void setSpiMode(uint8_t cs, uint8_t value);
void setSpiBaudRate(uint32_t baudRate);


#endif /* SPI_IP_H_ */
