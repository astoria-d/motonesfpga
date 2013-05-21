
MODULES=alu_adc.vhd alu_and.vhd alu.vhd

WORKDIR=../../work

GHDL_OPTION=--ieee=synopsys -fexplicit --workdir=$(WORKDIR)


OBJS = $(MODULES:.vhd=.o)
TEST_MODULES = $(addprefix testbench_, $(MODULES))

all: $(addprefix $(WORKDIR)/, $(OBJS))
#	echo $(OBJS)

.SUFFIXES: .vhd .o
#.vhd.o: 
$(addprefix $(WORKDIR)/, $(OBJS)): $(MODULES) $(TEST_MODULES)
	ghdl -a $(GHDL_OPTION) $(subst .o,.vhd, $(subst $(WORKDIR)/,, $@))
	ghdl -a $(GHDL_OPTION) $(subst .o,.vhd, $(subst $(WORKDIR)/,, testbench_$@))
	ghdl -e $(GHDL_OPTION) $(subst .o,, $(subst $(WORKDIR)/,, testbench_$@))

#all: $(OBJS)
#.SUFFIXES: .vhd .o
#.vhd.o: 
#	ghdl -a $(GHDL_OPTION) $<
#	ghdl -a $(GHDL_OPTION) testbench_$<
#	ghdl -e $(GHDL_OPTION) testbench_$*

#### old make rule...
analyze:
	ghdl -a $(GHDL_OPTION) $(FILES)
elaborate: analyze
	ghdl -e $(GHDL_OPTION) $(TEST_BIN)
run: elaborate
	ghdl -r $(TEST_BIN) --stop-time=500ns --vcd=testbench.vcd
	gtkwave testbench.vcd

clean:
	-rm $(addprefix $(WORKDIR)/, $(OBJS))
	-rm $(addprefix $(WORKDIR)/testbench_, $(OBJS))
	-rm $(addprefix $(WORKDIR)/e~testbench_, $(OBJS))
	-rm $(addprefix testbench_, $(subst .o,, $(OBJS)))
	-rm *.o *.cf *.vcd

