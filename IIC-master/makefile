SRC = bench.v iic_master.v iic_master_send.v iic_master_recv.v
MIDTARGET = run.out
TARGET = test.vcd

all : $(SRC)
	iverilog -o $(MIDTARGET) $(SRC)
	vvp -n $(MIDTARGET)
	gtkwave $(TARGET)