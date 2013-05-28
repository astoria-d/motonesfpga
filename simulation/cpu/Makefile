
MODULES=cpu_registers.vhd decoder.vhd data_latch.vhd \
		mos6502.vhd 
		#cpu_timing.vhd 

TEST_MODULE= testbench_mos6502.vhd

WORKDIR=../work

GHDL_OPTION=--ieee=synopsys -fexplicit --workdir=$(WORKDIR)

BIN=$(subst .vhd,, $(TEST_MODULE))

OBJS = $(MODULES:.vhd=.o) $(TEST_MODULE:.vhd=.o)

all: $(BIN)

.SUFFIXES: .vhd .o

$(addprefix $(WORKDIR)/, $(OBJS)): $(MODULES) $(TEST_MODULE)
	ghdl -a $(GHDL_OPTION) $(subst .o,.vhd, $(subst $(WORKDIR)/,, $@))

$(BIN): $(addprefix $(WORKDIR)/, $(OBJS))
	ghdl -e $(GHDL_OPTION) $(BIN)

clean:
	-rm $(addprefix $(WORKDIR)/, $(OBJS))
	-rm $(addprefix $(WORKDIR)/testbench_, $(OBJS))
	-rm $(addprefix $(WORKDIR)/e~testbench_, $(OBJS))
	-rm $(addprefix testbench_, $(subst .o,, $(OBJS)))
	-rm *.o *.cf *.vcd

