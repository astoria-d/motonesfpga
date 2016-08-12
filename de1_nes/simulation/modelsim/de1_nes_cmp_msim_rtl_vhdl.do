

transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {../../motonesfpga_common.vhd}
vcom -93 -work work {../../address_decoder.vhd}
vcom -93 -work work {../../clock/clock_divider.vhd}
vcom -93 -work work {../../mem/ram.vhd}
vcom -93 -work work {../../apu/apu.vhd}

#ppu block...
#vcom -93 -work work {../../mem/chr_rom.vhd}
#vcom -93 -work work {../../ppu/ppu.vhd}
#vcom -93 -work work {../../ppu/ppu_registers.vhd}
#vcom -93 -work work {../../ppu/vga_ppu.vhd}
vcom -93 -work work {../../dummy-ppu.vhd}

#cpu block...
vcom -93 -work work {../../mem/prg_rom.vhd}
vcom -93 -work work {../../cpu/cpu_registers.vhd}
vcom -93 -work work {../../cpu/alu.vhd}
vcom -93 -work work {../../cpu/decoder.vhd}
vcom -93 -work work {../../cpu/mos6502.vhd}

#vcom -93 -work work {../../dummy-mos6502.vhd}

vcom -93 -work work {../../de1_nes.vhd}

vcom -93 -work work {../../testbench_motones_sim.vhd}

