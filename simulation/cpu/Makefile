
TEST_FILES=testbench_regn.vhd 
FILES=regn.vhd $(TEST_FILES)
TEST_BIN=testbench_regn

GHDL_OPTION=--ieee=synopsys -fexplicit --workdir=../work


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

