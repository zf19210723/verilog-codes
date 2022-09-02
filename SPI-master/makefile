SRC = bench.v spi_master.v spi_master_recv.v spi_master_send.v
MIDTARGET = run.out
TARGET = test.vcd

all : $(SRC)
	iverilog -o $(MIDTARGET) $(SRC)
	vvp -n $(MIDTARGET)
	gtkwave $(TARGET)