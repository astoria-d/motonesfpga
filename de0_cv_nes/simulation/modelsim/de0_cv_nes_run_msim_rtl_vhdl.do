transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {../../chip_selector.vhd}
vcom -93 -work work {../../mem/ram.vhd}
vcom -93 -work work {../../mem/chr_rom.vhd}
vcom -93 -work work {../../ppu/ppu.vhd}
vcom -93 -work work {../../ppu/render.vhd}
vcom -93 -work work {../../dummy-mos6502.vhd}

vcom -93 -work work {../../de0_cv_nes.vhd}
vcom -93 -work work {../../testbench_motones_sim.vhd}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L cyclonev -L rtl_work -L work -voptargs="+acc"  testbench_motones_sim

##script custom part...

add wave -label rst_n               sim:/testbench_motones_sim/sim_board/pi_rst_n;
add wave -label base_clk            sim:/testbench_motones_sim/sim_board/pi_base_clk;
add wave -label wr_cpu_en           sim:/testbench_motones_sim/sim_board/wr_cpu_en;
add wave -label r_nw                sim:/testbench_motones_sim/sim_board/wr_r_nw;
add wave -label addr -radix hex     sim:/testbench_motones_sim/sim_board/wr_addr;
add wave -label d_io -radix hex     sim:/testbench_motones_sim/sim_board/wr_d_io;


add wave -divider ppu
add wave -label pi_ce_n         -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/pi_ce_n;
add wave -label ppu_ctrl        -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/reg_ppu_ctrl;
add wave -label ppu_mask        -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/reg_ppu_mask;
add wave -label ppu_status      -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/pi_ppu_status;
add wave -label oam_addr        -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/reg_oam_addr;
add wave -label oam_data        -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/reg_oam_data;
add wave -label ppu_scroll_x    -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/reg_ppu_scroll_x;
add wave -label ppu_scroll_y    -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/reg_ppu_scroll_y;
add wave -label ppu_addr        -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/reg_ppu_addr;
add wave -label ppu_data        -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/reg_ppu_data;

add wave -divider vram
add wave -label v_rd_n        -radix hex sim:/testbench_motones_sim/sim_board/wr_v_rd_n;
add wave -label v_wr_n        -radix hex sim:/testbench_motones_sim/sim_board/wr_v_wr_n;
add wave -label vram_addr        -radix hex sim:/testbench_motones_sim/sim_board/wr_v_addr;
add wave -label vram_data        -radix hex sim:/testbench_motones_sim/sim_board/wr_v_data;

add wave -divider render
#add wave -label vga_x       sim:/testbench_motones_sim/sim_board/render_inst/reg_vga_x;
#add wave -label vga_y       sim:/testbench_motones_sim/sim_board/render_inst/reg_vga_y;
add wave -label nes_x       sim:/testbench_motones_sim/sim_board/render_inst/reg_nes_x;
add wave -label nes_y       sim:/testbench_motones_sim/sim_board/render_inst/reg_nes_y;
add wave -label wr_rnd_en  sim:/testbench_motones_sim/sim_board/wr_rnd_en;
add wave -label reg_v_cur_state sim:/testbench_motones_sim/sim_board/render_inst/reg_v_cur_state;


add wave -divider vga
add wave -label h_sync_n       sim:/testbench_motones_sim/sim_board/po_h_sync_n;
add wave -label v_sync_n    sim:/testbench_motones_sim/sim_board/po_v_sync_n;
add wave -label r       sim:/testbench_motones_sim/sim_board/po_r;
add wave -label g       sim:/testbench_motones_sim/sim_board/po_g;
add wave -label b       sim:/testbench_motones_sim/sim_board/po_b;


#add wave -radix hex sim:/testbench_motones_sim/sim_board/vram_plt_inst/*;


view structure
view signals

run 4 us
wave zoom full

run 162 us

