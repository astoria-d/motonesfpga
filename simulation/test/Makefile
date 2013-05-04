

all:
	ghdl -a ha.vhdl
	ghdl -a testb_file.vhdl
	ghdl -e testb_file

run:
	ghdl -r testb_file --stop-time=500ns --vcd=testb_file.vcd
	gtkwave testb_file.vcd

clean:
	rm *.o *.cf *.vcd testb_file

