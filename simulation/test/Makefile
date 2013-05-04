
FILES=ha.vhd testbench.vhd

all: eraborate

analyze:
	ghdl -a $(FILES)

eraborate: analyze
	ghdl -e testbench

run:
	ghdl -r testbench --stop-time=500ns --vcd=testb_file.vcd
	gtkwave testbench.vcd

clean:
	rm *.o *.cf *.vcd testbench

