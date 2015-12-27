transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {../../../../de1_nes/motonesfpga_common.vhd}
vcom -93 -work work {../../../../de1_nes/mem/chr_rom.vhd}
vcom -93 -work work {../../../../de1_nes/address_decoder.vhd}
vcom -93 -work work {../../../../de1_nes/mem/ram.vhd}
vcom -93 -work work {../../../../de1_nes/ppu/ppu_registers.vhd}
vcom -93 -work work {../../../../de1_nes/clock/clock_divider.vhd}
vcom -93 -work work {../../vga.vhd}
vcom -93 -work work {../../render.vhd}
vcom -93 -work work {../../ppu.vhd}
vcom -93 -work work {../../qt_proj_test5.vhd}
vcom -93 -work work {../../testbench_qt_proj_test5.vhd}


vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L cycloneii -L rtl_work -L work -voptargs="ê "  testbench_qt_proj_test5

##add wave *



add wave  -label rst_n sim:/testbench_qt_proj_test5/sim_board/rst_n
add wave  -label cpu_clk sim:/testbench_qt_proj_test5/sim_board/cpu_clk
add wave  -label ppu_clk sim:/testbench_qt_proj_test5/sim_board/ppu_clk

#add wave  sim:/testbench_qt_proj_test5/base_clk
#add wave  -label emu_ppu_clk sim:/testbench_qt_proj_test5/sim_board/ppu_inst/render_inst/vga_render_inst/emu_ppu_clk

add wave -divider ppu

add wave  -label cpu_addr -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/cpu_addr
add wave  -label cpu_d -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/cpu_d

add wave  -label ppu_ce_n sim:/testbench_qt_proj_test5/sim_board/ppu_inst/ce_n
add wave -label ppu_clk_cnt -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/ppu_clk_cnt
add wave  -label ppu_ctrl -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/ppu_ctrl
add wave  -label ppu_mask -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/ppu_mask
add wave -label ppu_status -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/ppu_status
add wave -label ppu_addr -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/ppu_addr 
add wave -label ppu_data -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/ppu_data

add wave -divider vga_pos
add wave  -label nes_x          -radix decimal -unsigned  sim:/testbench_qt_proj_test5/sim_board/ppu_inst/render_inst/vga_render_inst/nes_x
add wave  -label nes_y          -radix decimal -unsigned  sim:/testbench_qt_proj_test5/sim_board/ppu_inst/render_inst/vga_render_inst/nes_y
add wave  -label dbg_disp_nt    -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/render_inst/vga_render_inst/vga_render_inst/dbg_disp_nt
add wave  -label dbg_disp_attr  -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/render_inst/vga_render_inst/vga_render_inst/disp_attr
add wave  -label dbg_disp_ptn_h -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/render_inst/vga_render_inst/vga_render_inst/dbg_disp_ptn_h
add wave  -label dbg_disp_ptn_l -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/render_inst/vga_render_inst/vga_render_inst/dbg_disp_ptn_l

add wave -divider sprite

add wave  -label oam_bus_ce_n                sim:/testbench_qt_proj_test5/sim_board/ppu_inst/oam_bus_ce_n
add wave  -label p_oam_ram_ce_n                sim:/testbench_qt_proj_test5/sim_board/ppu_inst/render_inst/vga_render_inst/vga_render_inst/p_oam_ram_ce_n
add wave  -label p_oam_r_n                sim:/testbench_qt_proj_test5/sim_board/ppu_inst/render_inst/vga_render_inst/vga_render_inst/p_oam_r_n
add wave  -label p_oam_w_n                sim:/testbench_qt_proj_test5/sim_board/ppu_inst/render_inst/vga_render_inst/vga_render_inst/p_oam_w_n
add wave  -label p_oam_addr     -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/render_inst/vga_render_inst/vga_render_inst/p_oam_addr
add wave  -label p_oam_data     -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/render_inst/vga_render_inst/vga_render_inst/p_oam_data

#add wave  -label s_oam_ram_ce_n                sim:/testbench_qt_proj_test5/sim_board/ppu_inst/render_inst/vga_render_inst/vga_render_inst/s_oam_ram_ce_n
#add wave  -label s_oam_r_n                sim:/testbench_qt_proj_test5/sim_board/ppu_inst/render_inst/vga_render_inst/vga_render_inst/s_oam_r_n
#add wave  -label s_oam_w_n                sim:/testbench_qt_proj_test5/sim_board/ppu_inst/render_inst/vga_render_inst/vga_render_inst/s_oam_w_n
#add wave  -label s_oam_addr     -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/render_inst/vga_render_inst/vga_render_inst/s_oam_addr
#add wave  -label s_oam_data     -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/render_inst/vga_render_inst/vga_render_inst/s_oam_data


add wave -divider vram
add wave -label ale sim:/testbench_qt_proj_test5/sim_board/ale
add wave -label rd_n sim:/testbench_qt_proj_test5/sim_board/rd_n
add wave -label wr_n sim:/testbench_qt_proj_test5/sim_board/wr_n

add wave  -label vram_a   -radix hex sim:/testbench_qt_proj_test5/sim_board/vram_a
add wave  -label vram_ad  -radix hex sim:/testbench_qt_proj_test5/sim_board/vram_ad
add wave  -label v_addr   -radix hex sim:/testbench_qt_proj_test5/sim_board/v_addr
#add wave  -label plt_addr -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/render_inst/vga_render_inst/vga_render_inst/plt_addr
#add wave  -label plt_data -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/render_inst/vga_render_inst/vga_render_inst/plt_data



add wave -divider nt_ram
#add wave  -label ce_n   sim:/testbench_qt_proj_test5/sim_board/vram_nt0/ce_n
#add wave  -label oe_n   sim:/testbench_qt_proj_test5/sim_board/vram_nt0/oe_n
#add wave  -label we_n   sim:/testbench_qt_proj_test5/sim_board/vram_nt0/we_n
#add wave  -label addr   -radix hex sim:/testbench_qt_proj_test5/sim_board/vram_nt0/addr
#add wave  -label data   -radix hex sim:/testbench_qt_proj_test5/sim_board/vram_nt0/d_io

add wave -divider vga_output
add wave  -label h_sync_n   sim:/testbench_qt_proj_test5/sim_board/h_sync_n
add wave  -label v_sync_n   sim:/testbench_qt_proj_test5/sim_board/v_sync_n
add wave  -label r          -radix hex sim:/testbench_qt_proj_test5/sim_board/r
add wave  -label g          -radix hex sim:/testbench_qt_proj_test5/sim_board/g
add wave  -label b          -radix hex sim:/testbench_qt_proj_test5/sim_board/b


view structure
view signals

run 500 us
wave zoom full

run 1000 us
wave zoom full
