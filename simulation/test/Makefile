
TEST_FILES=testbench_ha.vhd testbench_fa.vhd testbench_adder8.vhd 
FILES=ha.vhd fa.vhd adder8.vhd $(TEST_FILES)
TEST_BIN=testbench_adder8

GHDL_OPTION=--ieee=synopsys #-fexplicit


all: elaborate

analyze:
	ghdl -a $(GHDL_OPTION) $(FILES)

elaborate: analyze
	ghdl -e $(GHDL_OPTION) $(TEST_BIN)

run: elaborate
	ghdl -r $(TEST_BIN) --stop-time=500ns --vcd=testbench.vcd
#	gtkwave testbench.vcd

clean:
	rm *.o *.cf *.vcd $(TEST_BIN)

