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
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/ppu/vga.vhd}
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
add wave -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/exec_cycle

add wave -divider regs
add wave -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/acc/q
add wave -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/status_register/status_val
add wave -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/sp/q
add wave -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/x/q
add wave -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/y/q


##add wave -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/status_reg

add wave -divider ppu

add wave sim:/testbench_motones_sim/sim_board/dbg_ppu_ce_n
add wave sim:/testbench_motones_sim/sim_board/dbg_ppu_clk

add wave -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_clk_cnt

add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_ctrl
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_mask
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_status
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_addr 
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_data
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_x
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_y

###add wave sim:/testbench_motones_sim/sim_board/cpu_inst/*

add wave -divider render

add wave -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/pos_x \
sim:/testbench_motones_sim/sim_board/ppu_inst/pos_y 

add wave -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/nes_r \
sim:/testbench_motones_sim/sim_board/ppu_inst/nes_g \
sim:/testbench_motones_sim/sim_board/ppu_inst/nes_b

add wave sim:/testbench_motones_sim/sim_board/ppu_inst/h_sync_n \
sim:/testbench_motones_sim/sim_board/ppu_inst/v_sync_n

view structure
view signals
#run 100 us
run 80 us
wave zoom full

