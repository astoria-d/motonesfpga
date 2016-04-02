##
## run this script on modelsim
## > do de1_nes_run_msim_rtl_vhdl.do
##


transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/motonesfpga_common.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/mem/ram.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/ppu/ppu_registers.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/clock/clock_divider.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/address_decoder.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/de1_nes.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/mem/chr_rom.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/ppu/vga_ppu.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/ppu/ppu.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/dummy-mos6502.vhd}

#vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/apu/apu.vhd}
#vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/mem/prg_rom.vhd}
#vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/cpu/cpu_registers.vhd}
#vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/cpu/mos6502.vhd}
#vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/cpu/decoder.vhd}
#vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/cpu/alu.vhd}

vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/testbench_motones_sim.vhd}

vsim -t 1ps -L lpm -L altera -L altera_mf -L sgate -L cycloneii -L rtl_work -L work testbench_motones_sim

##add wave sim:/testbench_motones_sim/sim_board/ppu_clk

add wave -label rst_n sim:/testbench_motones_sim/sim_board/rst_n;
add wave -label r_nw sim:/testbench_motones_sim/sim_board/r_nw;
add wave -label cpu_clk sim:/testbench_motones_sim/sim_board/cpu_clk
add wave -label nmi_n sim:/testbench_motones_sim/sim_board/nmi_n
add wave -label addr -radix hex sim:/testbench_motones_sim/sim_board/addr
add wave -label d_io -radix hex sim:/testbench_motones_sim/sim_board/d_io

#add wave -label instruction -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/instruction
#add wave -label int_d_bus -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/int_d_bus
#add wave -label exec_cycle -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/exec_cycle

#add wave -divider regs
#add wave -label acc -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/acc/q
#add wave -label status_val -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/status_register/status_val
#add wave -label sp -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/sp/q
#add wave -label x -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/x/q
#add wave -label y -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/y/q


##add wave -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/status_reg

add wave -divider ppu

add wave -label ppu_ce_n sim:/testbench_motones_sim/sim_board/ppu_inst/ce_n
add wave -label ppu_clk sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_clk

add wave -label ppu_clk_cnt -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_clk_cnt

add wave -label ppu_ctl -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_ctrl
add wave -label ppu_mask -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_mask
add wave -label ppu_status -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_status


add wave -label ppu_addr_cnt -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_addr_cnt
#add wave -label ppu_addr_we_n -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_addr_we_n
#add wave -label ppu_addr_in -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_addr_in
#add wave -label ppu_addr_inc1 -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_addr_inc1
#add wave -label ppu_addr_inc32 -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_addr_inc32

add wave -label ppu_addr -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_addr
add wave -label ppu_data -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_data
#add wave -label ppu_scr_x -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_scrl_x
#add wave -label ppu_scr_y -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_scrl_y



add wave -divider vram
add wave  -radix hex -label nt0_ce_n sim:/testbench_motones_sim/sim_board/nt0_ce_n
add wave  -radix hex -label v_addr sim:/testbench_motones_sim/sim_board/v_addr
add wave  -radix hex -label vram_ad sim:/testbench_motones_sim/sim_board/vram_ad

add wave  -label ale sim:/testbench_motones_sim/sim_board/ale
add wave  -label rd_n sim:/testbench_motones_sim/sim_board/rd_n
add wave  -label wr_n sim:/testbench_motones_sim/sim_board/wr_n


add wave -divider render

#add wave -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/nes_r \
#sim:/testbench_motones_sim/sim_board/ppu_inst/nes_g \
#sim:/testbench_motones_sim/sim_board/ppu_inst/nes_b

add wave -label vga_clk sim:/testbench_motones_sim/sim_board/ppu_inst/vga_clk
add wave -label emu_ppu_clk sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/ppu_render_inst/ppu_clk

add wave -label h_sync_n sim:/testbench_motones_sim/sim_board/ppu_inst/h_sync_n
add wave -label v_sync_n sim:/testbench_motones_sim/sim_board/ppu_inst/v_sync_n

add wave -label vga_x -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/x_inst/q
add wave -label vga_y -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/y_inst/q

add wave -label nes_x -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/ppu_render_inst/cur_x
add wave -label nes_y -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/ppu_render_inst/cur_y


view structure
view signals

run 2 us
wave zoom full

run 2 us
#run 65 us

