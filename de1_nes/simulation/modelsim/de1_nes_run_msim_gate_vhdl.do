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

add wave -divider cpu

##add wave sim:/testbench_motones_sim/sim_board/dbg_ppu_clk
##add wave  sim:/testbench_motones_sim/sim_board/dbg_mem_clk

add wave sim:/testbench_motones_sim/sim_board/dbg_r_nw

add wave sim:/testbench_motones_sim/sim_board/dbg_cpu_clk

add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_addr
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_d_io

add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_instruction
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_int_d_bus

add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_exec_cycle

add wave -divider regs

#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_index_bus;
#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_acc_bus;
##    dbg_pcl, dbg_pch, 

add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_acc
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_sp
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_status
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_x
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_y


add wave -divider ppu

add wave sim:/testbench_motones_sim/sim_board/dbg_ppu_ce_n
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_ctrl
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_mask
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_status
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_addr 
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_data
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_x
add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_y


add wave -divider debug

#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_idl_h
#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_idl_l
#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_dbb_r
#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_dbb_w

#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_dec_oe_n
#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_dec_val
#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_int_dbus

#add wave -divider debug2


#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_status_val
#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_stat_we_n

view structure
view signals
#run -all
run 10 us

#wave zoom range 3339700 ps 5138320 ps
wave zoom full

#run 12 us

#run 1000 us

##wave addcursor 907923400 ps

