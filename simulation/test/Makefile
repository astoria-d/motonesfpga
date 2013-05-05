
FILES=ha.vhd fa.vhd testbench_fa.vhd
TEST=testbench_fa

all: eraborate

analyze:
	ghdl -a $(FILES)

eraborate: analyze
	ghdl -e $(TEST)

run:
	ghdl -r testbench --stop-time=500ns --vcd=testb_file.vcd
	gtkwave testbench.vcd

clean:
	rm *.o *.cf *.vcd $(TEST)

