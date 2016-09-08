transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {C:/Users/motooka/Documents/001-proj/999.my-proj/001.nes-fpga/repo/motonesfpga/de0_cv_nes/de0_cv_nes.vhd}

vcom -93 -work work {C:/Users/motooka/Documents/001-proj/999.my-proj/001.nes-fpga/repo/motonesfpga/de0_cv_nes/testbench_motones_sim.vhd}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L cyclonev -L rtl_work -L work -voptargs="+acc"  testbench_motones_sim

##script custom part...


add wave -label rst_n sim:/testbench_motones_sim/sim_board/rst_n;
add wave -label r_nw sim:/testbench_motones_sim/sim_board/r_nw;


view structure
view signals

run 8 us
wave zoom full

#run 430 us

