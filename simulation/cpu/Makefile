
MODULES=regn.vhd

WORKDIR=../work

GHDL_OPTION=--ieee=synopsys -fexplicit --workdir=$(WORKDIR)


OBJS = $(MODULES:.vhd=.o)
TEST_MODULES = $(addprefix testbench_, $(MODULES))

all: $(addprefix $(WORKDIR)/, $(OBJS))

.SUFFIXES: .vhd .o
$(addprefix $(WORKDIR)/, $(OBJS)): $(MODULES) $(TEST_MODULES)
	ghdl -a $(GHDL_OPTION) $(subst .o,.vhd, $(subst $(WORKDIR)/,, $@))
	ghdl -a $(GHDL_OPTION) $(subst .o,.vhd, $(subst $(WORKDIR)/,, testbench_$@))
	ghdl -e $(GHDL_OPTION) $(subst .o,, $(subst $(WORKDIR)/,, testbench_$@))

clean:
	-rm $(addprefix $(WORKDIR)/, $(OBJS))
	-rm $(addprefix $(WORKDIR)/testbench_, $(OBJS))
	-rm $(addprefix $(WORKDIR)/e~testbench_, $(OBJS))
	-rm $(addprefix testbench_, $(subst .o,, $(OBJS)))
	-rm *.o *.cf *.vcd

