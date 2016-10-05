transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {../../chip_selector.vhd}
vcom -93 -work work {../../mem/ram.vhd}
vcom -93 -work work {../../apu.vhd}

#vcom -93 -work work {../../mem/chr_rom.vhd}
#vcom -93 -work work {../../ppu/ppu.vhd}
#vcom -93 -work work {../../ppu/render.vhd}
vcom -93 -work work {../../dummy-ppu.vhd}

#vcom -93 -work work {../../dummy-mos6502.vhd}
#vcom -93 -work work {../../dummy-smb-rom.vhd}
vcom -93 -work work {../../mem/prg_rom.vhd}
vcom -93 -work work {../../mos6502.vhd}

vcom -93 -work work {../../de0_cv_nes.vhd}
vcom -93 -work work {../../testbench_motones_sim.vhd}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L cyclonev -L rtl_work -L work -voptargs="+acc"  testbench_motones_sim

##script custom part...

#run 450ms

#################################### General.... ###########################################

#add wave -label dbg_cnt -radix hex  sim:/testbench_motones_sim/sim_board/po_dbg_cnt;
add wave -label po_exc_cnt -radix hex  sim:/testbench_motones_sim/sim_board/po_exc_cnt;
add wave -label rst_n               sim:/testbench_motones_sim/sim_board/pi_rst_n;
add wave -label wr_nmi_n            sim:/testbench_motones_sim/sim_board/wr_nmi_n;
#add wave -label base_clk            sim:/testbench_motones_sim/sim_board/pi_base_clk;
#add wave -label wr_cpu_en           sim:/testbench_motones_sim/sim_board/wr_cpu_en;
add wave -label wr_cpu_en           sim:/testbench_motones_sim/sim_board/wr_cpu_en(0);
add wave -label wr_oe_n             sim:/testbench_motones_sim/sim_board/wr_oe_n;
add wave -label wr_we_n             sim:/testbench_motones_sim/sim_board/wr_we_n;
add wave -label addr -radix hex     sim:/testbench_motones_sim/sim_board/wr_addr;
add wave -label d_io -radix hex     sim:/testbench_motones_sim/sim_board/wr_d_io;

#################################### CPU part.... ###########################################

#add wave -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/reg*;
add wave -divider cpu

add wave -label reg_inst -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/reg_inst;
add wave -label reg_acc -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/reg_acc;
add wave -label reg_x -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/reg_x;
add wave -label reg_y -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/reg_y;
add wave -label reg_sp -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/reg_sp;
add wave -label reg_status -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/reg_status;

#add wave -divider internal_reg
#add wave -label reg_main_cur_state  sim:/testbench_motones_sim/sim_board/cpu_inst/reg_main_state;
##add wave -label reg_sub_cur_state   sim:/testbench_motones_sim/sim_board/cpu_inst/reg_sub_state;
#add wave -label reg_pc_l -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/reg_pc_l;
#add wave -label reg_pc_h -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/reg_pc_h;
#add wave -label reg_idl_l -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/reg_idl_l;
#add wave -label reg_idl_h -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/reg_idl_h;
#add wave -label reg_tmp_pg_crossed  sim:/testbench_motones_sim/sim_board/cpu_inst/reg_tmp_pg_crossed;


view structure
view signals

run 15 us
wave zoom full

run 1800us
