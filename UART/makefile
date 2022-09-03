SRC = *.v
MIDTARGET = run.out
TARGET = test.vcd

all : $(SRC)
	iverilog -o $(MIDTARGET) $(SRC)
	vvp -n $(MIDTARGET)
	gtkwave $(TARGET)

.PHONY : clean
clean :
	rm -rf $(MIDTARGET) $(TARGET)