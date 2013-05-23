
DIRS=clock mem cpu/alu cpu 
MODULES=motones_sim.vhd address_decoder.vhd
WORKDIR=work

ROOT_DIR=$(CURDIR)

GHDL_OPTION=--ieee=synopsys -fexplicit --workdir=$(WORKDIR)

OBJS = $(MODULES:.vhd=.o)
TEST_MODULES = $(addprefix testbench_, $(MODULES))

all: subdirs $(addprefix $(WORKDIR)/, $(OBJS))

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
	
subdirs:
	for dir in $(DIRS); do \
		make -C $(ROOT_DIR)/$$dir; \
	done

rclean: clean
	-rm $(WORKDIR)/*

