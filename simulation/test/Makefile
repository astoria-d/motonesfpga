
TEST_FILES=testbench_ha.vhd testbench_fa.vhd
FILES=ha.vhd fa.vhd $(TEST_FILES)
TEST_BIN=testbench_fa

all: elaborate

analyze:
	ghdl -a $(FILES)

elaborate: analyze
	ghdl -e $(TEST_BIN)

run: elaborate
	ghdl -r $(TEST_BIN) --stop-time=500ns --vcd=testbench.vcd
#	gtkwave testbench.vcd

clean:
	rm *.o *.cf *.vcd $(TEST_BIN)

