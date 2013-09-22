transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/motonesfpga_common.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/mem/ram.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/ppu/ppu_registers.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/cpu/cpu_registers.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/clock/clock_divider.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/apu/apu.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/cpu/mos6502.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/address_decoder.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/de1_nes.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/mem/prg_rom.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/mem/chr_rom.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/ppu/ppu.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/ppu/render.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/cpu/decoder.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/cpu/alu.vhd}

vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/testbench_motones_sim.vhd}

vsim -t 1ps -L lpm -L altera -L altera_mf -L sgate -L cycloneii -L rtl_work -L work testbench_motones_sim

##add wave sim:/testbench_motones_sim/sim_board/ppu_clk

add wave sim:/testbench_motones_sim/sim_board/rst_n;
add wave sim:/testbench_motones_sim/sim_board/r_nw;
add wave sim:/testbench_motones_sim/sim_board/cpu_clk
add wave -radix hex sim:/testbench_motones_sim/sim_board/addr
add wave -radix hex sim:/testbench_motones_sim/sim_board/d_io
add wave -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/instruction
add wave -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/int_d_bus
add wave -divider regs
add wave -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/acc/q
add wave -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/sp/q
add wave -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/status_register/status_val
add wave -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/x/q
add wave -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/y/q


###add wave sim:/testbench_motones_sim/sim_board/cpu_inst/*

view structure
view signals
run 100 us
