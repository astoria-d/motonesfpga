
TEST_FILES=testbench_alu.vhd testbench_adc.vhd 
FILES=alu.vhd alu_adc.vhd alu_and.vhd $(TEST_FILES)
TEST_BIN=testbench_alu

GHDL_OPTION=--ieee=synopsys -fexplicit


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

