obj-m += spi.o

DIR=/lib/modules/$(shell uname -r)/build

all:
	make -C $(DIR) M=$(shell pwd) modules
	gcc -o spi spi_ip.c spi.c

clean:
	make -C $(DIR) M=$(shell pwd) clean
	