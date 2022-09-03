all:
	make -C ./PWM
	make -C ./SPI-master
	make -C ./UART

.PHONY : clean
clean:
	make -C ./PWM clean
	make -C ./SPI-master clean
	make -C ./UART clean