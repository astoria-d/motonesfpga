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

add wave  sim:/testbench_qt_proj_test5/base_clk
add wave  sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_clk

add wave  sim:/testbench_qt_proj_test5/sim_board/rst_n
#add wave  sim:/testbench_qt_proj_test5/sim_board/dbg_cpu_clk
#add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_addr
#add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_d_io
#add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_instruction
#add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_int_d_bus



add wave -divider vga_out
add wave  sim:/testbench_qt_proj_test5/sim_board/v_sync_n
add wave  sim:/testbench_qt_proj_test5/sim_board/h_sync_n
add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/r
add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/g
add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/b

add wave -divider vga_pos
add wave -radix decimal -unsigned  -label vga_x sim:/testbench_qt_proj_test5/sim_board/dbg_disp_ptn_h
add wave -radix decimal -unsigned  -label nes_x sim:/testbench_qt_proj_test5/sim_board/dbg_disp_ptn_l



#add wave -divider status

#add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_d1
#add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_d2
#add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_d_out
#add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_ea_carry
#add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_carry_clr_n
#add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_gate_n



#add wave -divider status_debug

#add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_status
#add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_dec_oe_n
#add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_status_val
#add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_stat_we_n

view structure
view signals

###run 10 us
run 3 us

run 50 us

wave zoom full

