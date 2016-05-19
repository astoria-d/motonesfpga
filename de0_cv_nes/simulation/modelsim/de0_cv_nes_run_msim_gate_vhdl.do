transcript on
if {[file exists gate_work]} {
	vdel -lib gate_work -all
}
vlib gate_work
vmap work gate_work

vcom -93 -work work {de0_cv_nes.vho}

vcom -93 -work work {C:/Users/motooka/Documents/001-proj/999.my-proj/001.nes-fpga/repo/motonesfpga/de0_cv_nes/testbench_motones_sim.vhd}

vsim -t 1ps +transport_int_delays +transport_path_delays -sdftyp /NA=de0_cv_nes_vhd.sdo -L altera -L altera_lnsim -L cyclonev -L gate_work -L work -voptargs="+acc"  testbench_motones_sim

add wave *
view structure
view signals
run -all
