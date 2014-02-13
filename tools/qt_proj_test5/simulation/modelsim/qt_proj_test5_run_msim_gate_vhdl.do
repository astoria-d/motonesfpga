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

add wave  sim:/testbench_qt_proj_test5/sim_board/rst_n
add wave  sim:/testbench_qt_proj_test5/sim_board/dbg_ppu_clk
add wave  sim:/testbench_qt_proj_test5/dbg_mem_clk  

add wave  sim:/testbench_qt_proj_test5/sim_board/dbg_cpu_clk
#add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_addr
#add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_d_io
#add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_instruction
#add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_int_d_bus


add wave -divider vga_internal
add wave -radix decimal -unsigned sim:/testbench_qt_proj_test5/sim_board/dbg_pos_x
add wave -radix decimal -unsigned sim:/testbench_qt_proj_test5/sim_board/dbg_pos_y

add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_nes_r
add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_nes_g
add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_nes_b

add wave -radix decimal -unsigned \
sim:/testbench_qt_proj_test5/sim_board/dbg_vga_x        \
sim:/testbench_qt_proj_test5/sim_board/dbg_nes_x        \
sim:/testbench_qt_proj_test5/sim_board/dbg_vga_y        

#sim:/testbench_qt_proj_test5/sim_board/dbg_nes_x_old        \

add wave -divider fifo
add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_f_wr
add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_f_in             
add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_f_rd
add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_f_out            
add wave -radix decimal -unsigned sim:/testbench_qt_proj_test5/sim_board/dbg_f_cnt           
add wave -radix decimal -unsigned sim:/testbench_qt_proj_test5/sim_board/dbg_bst_cnt          
add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_f_emp
add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_f_ful 
add wave -radix decimal -unsigned sim:/testbench_qt_proj_test5/sim_board/dbg_sw_state     

add wave -divider sdram_ctl
add wave -radix hex \
sim:/testbench_qt_proj_test5/sim_board/dbg_wbs_adr_i \
sim:/testbench_qt_proj_test5/sim_board/dbg_wbs_dat_i \
sim:/testbench_qt_proj_test5/sim_board/dbg_wbs_we_i \
sim:/testbench_qt_proj_test5/sim_board/dbg_wbs_tga_i \
sim:/testbench_qt_proj_test5/sim_board/dbg_wbs_cyc_i \
sim:/testbench_qt_proj_test5/sim_board/dbg_wbs_stb_i


#add wave -divider vga_out
#add wave  sim:/testbench_qt_proj_test5/sim_board/v_sync_n
#add wave  sim:/testbench_qt_proj_test5/sim_board/h_sync_n
#add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/r
#add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/g
#add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/b


view structure
view signals

run 3 us
wave zoom full

run 40 us

##run 400 us


