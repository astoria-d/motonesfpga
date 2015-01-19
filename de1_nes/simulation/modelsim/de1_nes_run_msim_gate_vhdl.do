transcript on
if {[file exists gate_work]} {
	vdel -lib gate_work -all
}
vlib gate_work
vmap work gate_work

vcom -93 -work work {de1_nes.vho}

vcom -93 -work work {../../testbench_motones_sim.vhd}

vsim -t 1ps +transport_int_delays +transport_path_delays -sdftyp /sim_board=de1_nes_vhd.sdo -L cycloneii -L gate_work -L work testbench_motones_sim

#add wave *


add wave -divider cpu
add wave -label rst_n       sim:/testbench_motones_sim/sim_board/rst_n
add wave -label r_nw       sim:/testbench_motones_sim/sim_board/dbg_r_nw
add wave -label cpu_clk       sim:/testbench_motones_sim/sim_board/dbg_cpu_clk
add wave  -label ppu_clk    sim:/testbench_motones_sim/sim_board/dbg_ppu_clk
add wave -label vga_clk   sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_x(4)
##add wave  sim:/testbench_motones_sim/sim_board/dbg_mem_clk



add wave -label addr       -radix hex sim:/testbench_motones_sim/sim_board/dbg_addr
add wave -label d_io       -radix hex sim:/testbench_motones_sim/sim_board/dbg_d_io

#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_instruction
#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_int_d_bus
#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_exec_cycle
#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_ea_carry     
#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_wait_a58_branch_next     


#add wave -divider regs

#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_acc
#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_sp
#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_status
#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_x
#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_y


add wave -divider ppu
add wave -label ppu_ctrl  -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_ctrl
add wave -label ppu_mask  -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_mask
#add wave  -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_status


add wave -divider vga_pos
add wave -label nes_x           -radix decimal -unsigned  -label nes_x sim:/testbench_motones_sim/sim_board/dbg_ppu_addr
add wave -label dbg_disp_nt     -radix hex sim:/testbench_motones_sim/sim_board/dbg_disp_nt
add wave -label dbg_disp_attr   -radix hex sim:/testbench_motones_sim/sim_board/dbg_disp_attr
add wave -label dbg_disp_ptn_h  -radix hex sim:/testbench_motones_sim/sim_board/dbg_disp_ptn_h
#add wave -label dbg_disp_ptn_l  -radix hex sim:/testbench_motones_sim/sim_board/dbg_disp_ptn_l

add wave -divider vram
add wave -label ale sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_x(0)
add wave -label rd_n sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_x(1)
add wave -label wr_n sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_x(2)
add wave -label nt0_ce_n sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_x(3)

add wave  -radix hex -label v_addr sim:/testbench_motones_sim/sim_board/dbg_addr
add wave  -radix hex -label vram_ad sim:/testbench_motones_sim/sim_board/dbg_ppu_status
add wave  -radix hex -label plt_addr sim:/testbench_motones_sim/sim_board/dbg_d_io
add wave  -radix hex -label plt_data sim:/testbench_motones_sim/sim_board/dbg_ppu_data



add wave -divider vga_out
add wave -label h_sync_n    sim:/testbench_motones_sim/sim_board/v_sync_n
add wave -label v_sync_n    sim:/testbench_motones_sim/sim_board/h_sync_n
add wave -label r           -radix hex sim:/testbench_motones_sim/sim_board/r
add wave -label g           -radix hex sim:/testbench_motones_sim/sim_board/g
add wave -label b           -radix hex sim:/testbench_motones_sim/sim_board/b


view structure
view signals
#run -all
run 10 us
run 5 us
#run 60 us

#wave zoom range 3339700 ps 5138320 ps
wave zoom full

#run 12 us

#run 1000 us

##wave addcursor 907923400 ps

