
vsim -t 1ps -L lpm -L altera -L altera_mf -L sgate -L cycloneii -L rtl_work -L work testbench_motones_sim


add wave -label rst_n sim:/testbench_motones_sim/sim_board/rst_n;
add wave -label nmi_n sim:/testbench_motones_sim/sim_board/cpu_inst/nmi_n;
add wave -label r_nw sim:/testbench_motones_sim/sim_board/r_nw;
add wave -label cpu_clk sim:/testbench_motones_sim/sim_board/cpu_clk
add wave -label addr -radix hex sim:/testbench_motones_sim/sim_board/addr
add wave -label d_io -radix hex sim:/testbench_motones_sim/sim_board/d_io

#cpu debug...
#add wave -label instruction -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/instruction
#add wave -label int_d_bus -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/int_d_bus
#add wave -label exec_cycle -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/exec_cycle
#add wave -label ea_carry -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/dec_inst/ea_carry

#add wave -divider cpu_regs
#add wave -label acc -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/acc/q
#add wave -label status_val -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/status_register/status_val
#add wave -label sp -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/sp/q
#add wave -label x -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/x/q
#add wave -label y -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/y/q
#
#add wave -label pcl -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/pcl_inst/q
#add wave -label pch -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/pch_inst/q
#add wave -label idl_l -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/idl_l/q


add wave -divider ppu
#add wave -label cpu_addr -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/cpu_addr
#add wave -label cpu_d -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/cpu_d
add wave -label ppu_clk sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_clk
add wave -label ppu_ce_n sim:/testbench_motones_sim/sim_board/ppu_inst/ce_n
add wave -label ppu_ctl -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_ctrl
add wave -label ppu_mask -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_mask
add wave -label ppu_status -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_status
add wave -label ppu_addr -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_addr
add wave -label ppu_data -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_data
add wave -label oam_addr -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/oam_addr
add wave -label oam_data -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/oam_data
add wave -label ppu_scr_x -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_scroll_x
add wave -label ppu_scr_y -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_scroll_y

add wave -divider vram
add wave -label emu_ppu_clk sim:/testbench_motones_sim/sim_board/ppu_inst/emu_ppu_clk
add wave -label ale sim:/testbench_motones_sim/sim_board/ppu_inst/ale
add wave -label rd_n sim:/testbench_motones_sim/sim_board/ppu_inst/rd_n
add wave -label wr_n sim:/testbench_motones_sim/sim_board/ppu_inst/wr_n
add wave -label vram_a -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/vram_a
add wave -label vram_ad -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/vram_ad


#add wave -divider render
##add wave -label vba_x -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/vga_x
#add wave -label nes_x -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/nes_x
##add wave -label vga_y -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/vga_y
#add wave -label nes_y -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/nes_y
##add wave -label disp_nt -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/ppu_render_inst/disp_nt
##add wave -label disp_attr -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/ppu_render_inst/disp_attr
##add wave -label attr_val -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/ppu_render_inst/attr_val
#
#
#add wave -divider vga
#add wave -label h_sync_n sim:/testbench_motones_sim/sim_board/ppu_inst/h_sync_n
#add wave -label v_sync_n sim:/testbench_motones_sim/sim_board/ppu_inst/v_sync_n
#add wave -label r -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/r
#add wave -label g -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/g
#add wave -label b -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/b



#add wave -divider
#add wave -radix hex  sim:/testbench_motones_sim/sim_board/clock_inst/*
#add wave -divider
#add wave -radix hex  sim:/testbench_motones_sim/sim_board/cpu_inst/dec_inst/*
#add wave -divider
#add wave -radix hex  sim:/testbench_motones_sim/sim_board/cpu_inst/ad_calc_inst/*
#add wave -divider
#add wave -radix hex  sim:/testbench_motones_sim/sim_board/cpu_inst/alu_inst/*

#add wave -divider apu
#add wave  -radix hex  sim:/testbench_motones_sim/sim_board/apu_inst/*

add wave -divider ppu
#add wave  -radix hex  sim:/testbench_motones_sim/sim_board/ppu_inst/*

view structure
view signals

run 15 us
wave zoom full
run 10 us

