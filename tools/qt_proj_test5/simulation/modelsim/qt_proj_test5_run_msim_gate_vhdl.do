transcript on
if {[file exists gate_work]} {
	vdel -lib gate_work -all
}
vlib gate_work
vmap work gate_work

vcom -93 -work work {qt_proj_test5.vho}

vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/tools/qt_proj_test5/testbench_qt_proj_test5.vhd}

vsim -t 1ps +transport_int_delays +transport_path_delays -sdftyp /sim_board=qt_proj_test5_vhd.sdo -L cycloneii -L gate_work -L work -voptargs="+acc"  testbench_qt_proj_test5

###add wave *

add wave  sim:/testbench_qt_proj_test5/base_clk
add wave  sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_clk

add wave  sim:/testbench_qt_proj_test5/sim_board/rst_n
add wave  sim:/testbench_qt_proj_test5/sim_board/dbg_cpu_clk
add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_addr
add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_d_io
add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_instruction
add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_int_d_bus


view structure
view signals
run 10 us
