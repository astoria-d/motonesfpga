transcript on
if {[file exists gate_work]} {
	vdel -lib gate_work -all
}
vlib gate_work
vmap work gate_work

vcom -93 -work work {de1_nes.vho}

vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/de1_nes/testbench_motones_sim.vhd}

vsim -t 10ps +transport_int_delays +transport_path_delays -sdftyp /sim_board=de1_nes_vhd.sdo -L cycloneii -L gate_work -L work testbench_motones_sim

#add wave *

add wave sim:/testbench_motones_sim/sim_board/rst_n
##add wave sim:/testbench_motones_sim/sim_board/dbg_ppu_clk
add wave sim:/testbench_motones_sim/sim_board/dbg_cpu_clk

add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_addr
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_d_io

add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_instruction
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_int_d_bus
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_exec_cycle

view structure
view signals
#run -all
run 10 us

#wave zoom range 3339700 ps 5138320 ps
wave zoom full

