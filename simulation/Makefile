DIRS=clock mem ppu dev cpu 
MODULES=address_decoder.vhd motones_sim.vhd 
WORKDIR=work
TEST_MODULE = testbench_motones_sim.vhd

ROOT_DIR=$(CURDIR)

GHDL_OPTION=--ieee=synopsys -fexplicit --workdir=$(WORKDIR)

OBJS = $(addprefix $(WORKDIR)/,$(addsuffix .o,$(basename $(MODULES) $(TEST_MODULE))))

BIN=$(subst .vhd,, $(TEST_MODULE))

all: $(BIN)

$(WORKDIR)/%.o: %.vhd
	ghdl -a $(GHDL_OPTION) $(subst .o,.vhd, $(subst $(WORKDIR)/,, $@))

$(BIN): $(DIRS) $(OBJS)
	for dir in $(DIRS); do \
		make -C $(ROOT_DIR)/$$dir; \
	done
	ghdl -e $(GHDL_OPTION) $(BIN)

clean:
	-rm $(OBJS)
	-rm $(BIN)
	-rm $(patsubst $(WORKDIR)/,$(WORKDIR)/e~, $(OBJS))
	-rm *.o *.cf *.vcd
	
rclean: clean
	-rm $(WORKDIR)/*

