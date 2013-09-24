transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/tools/qt_proj_test5/motonesfpga_common.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/tools/qt_proj_test5/ppu_registers.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/tools/qt_proj_test5/cpu_registers.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/tools/qt_proj_test5/clock_divider.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/tools/qt_proj_test5/qt_proj_test5.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/tools/qt_proj_test5/prg_rom.vhd}

vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/tools/qt_proj_test5/testbench_qt_proj_test5.vhd}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L cycloneii -L rtl_work -L work -voptargs="ê "  testbench_qt_proj_test5

##add wave *


add wave sim:/testbench_qt_proj_test5/sim_board/rst_n;
add wave sim:/testbench_qt_proj_test5/sim_board/r_nw;
add wave sim:/testbench_qt_proj_test5/sim_board/cpu_clk
add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/addr
add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/d_io

view structure
view signals
run 10 us
