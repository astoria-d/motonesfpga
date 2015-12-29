transcript on
if {[file exists gate_work]} {
	vdel -lib gate_work -all
}
vlib gate_work
vmap work gate_work

vcom -93 -work work {qt_proj_test5.vho}

vcom -93 -work work {../../testbench_qt_proj_test5.vhd}

vsim -t 1ps +transport_int_delays +transport_path_delays -sdftyp /sim_board=qt_proj_test5_vhd.sdo -L cycloneii -L gate_work -L work -voptargs="+acc"  testbench_qt_proj_test5

###add wave *

add wave  -label rst_n sim:/testbench_qt_proj_test5/sim_board/rst_n
add wave  -label cpu_clk sim:/testbench_qt_proj_test5/dbg_cpu_clk
#add wave  -label mem_clk sim:/testbench_qt_proj_test5/sim_board/dbg_mem_clk

add wave -divider cpu/io
#add wave -label r_nw  sim:/testbench_qt_proj_test5/sim_board/dbg_r_nw
add wave -label addr  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_addr
add wave -label d_io  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_d_io


add wave -divider ce-pins
add wave -label rom_ce_n sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_scrl_x(5)
add wave -label ram_ce_n sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_scrl_x(6)

add wave -divider ppu
add wave  -label ppu_clk sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_clk
add wave -label dbg_ppu_ce_n sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_ce_n
add wave -label ppu_ctrl  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_ctrl
add wave -label ppu_mask  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_mask
#add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_status
add wave -label ppu_addr -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_addr
add wave -label ppu_data -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_data


add wave -divider vga_pos
add wave -label vga_clk sim:/testbench_qt_proj_test5/sim_board/dbg_vga_clk
add wave -label dbg_disp_nt     -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_disp_nt
add wave -label dbg_disp_attr   -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_disp_attr
#add wave -label dbg_disp_ptn_h  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_disp_ptn_h
#add wave -label dbg_disp_ptn_l  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_disp_ptn_l

add wave -divider vram
add wave -label ale sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_scrl_x(0)
add wave -label rd_n sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_scrl_x(1)
add wave -label wr_n sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_scrl_x(2)
add wave -label nt0_ce_n sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_scrl_x(3)

add wave  -radix hex -label v_addr {sim:/testbench_qt_proj_test5/sim_board/dbg_disp_ptn_l (13 downto 0)}
#add wave  -radix hex -label vram_ad sim:/testbench_qt_proj_test5/sim_board/dbg_vram_ad


add wave -label plt_ce_n sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_scrl_y(5)
add wave -label plt_r_n sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_scrl_y(4)
add wave -label plt_w_n sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_scrl_y(3)
add wave  -radix hex -label plt_addr {sim:/testbench_qt_proj_test5/sim_board/dbg_disp_ptn_h(12 downto 8)}
add wave  -radix hex -label plt_data {sim:/testbench_qt_proj_test5/sim_board/dbg_disp_ptn_h(7 downto 0)}


#add wave -divider sprite
#add wave -label p_oam_ce_n sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_scrl_y(2)
#add wave -label p_oam_r_n sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_scrl_y(1)
#add wave -label p_oam_w_n sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_scrl_y(0)
#add wave -label p_oam_addr  -radix hex {sim:/testbench_qt_proj_test5/sim_board/dbg_disp_ptn_l(7 downto 0)}
#add wave -label p_oam_data  -radix hex {sim:/testbench_qt_proj_test5/sim_board/dbg_disp_ptn_l (15 downto 8)}


add wave -divider vga_out
add wave -label h_sync_n    sim:/testbench_qt_proj_test5/sim_board/v_sync_n
add wave -label v_sync_n    sim:/testbench_qt_proj_test5/sim_board/h_sync_n
add wave -label r           -radix hex sim:/testbench_qt_proj_test5/sim_board/r
add wave -label g           -radix hex sim:/testbench_qt_proj_test5/sim_board/g
add wave -label b           -radix hex sim:/testbench_qt_proj_test5/sim_board/b


view structure
view signals

run 10 us
wave zoom full


run 100 us
wave zoom full

