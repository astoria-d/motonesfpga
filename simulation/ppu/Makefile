
MODULES=ppu.vhd \


TEST_MODULE= testbench_ppu.vhd

WORKDIR=../work

GHDL_OPTION=--ieee=synopsys -fexplicit --workdir=$(WORKDIR)

BIN=$(subst .vhd,, $(TEST_MODULE))

OBJS = $(addprefix $(WORKDIR)/,$(addsuffix .o,$(basename $(MODULES) $(TEST_MODULE))))


all: $(BIN)

$(WORKDIR)/%.o: %.vhd
	ghdl -a $(GHDL_OPTION) $(subst .o,.vhd, $(subst $(WORKDIR)/,, $@))

$(BIN): $(OBJS)
	ghdl -e $(GHDL_OPTION) $(BIN)

clean:
	-rm $(OBJS)
	-rm $(patsubst $(WORKDIR)/,$(WORKDIR)/e~, $(OBJS))
	-rm *.o *.cf *.vcd

