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
add wave -label nmi         sim:/testbench_motones_sim/sim_board/dbg_nmi
add wave -label cpu_clk       sim:/testbench_motones_sim/sim_board/dbg_cpu_clk
#add wave -label vga_clk   sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_x(4)
#add wave -label mem_clk sim:/testbench_motones_sim/sim_board/dbg_mem_clk



add wave -label r_nw       sim:/testbench_motones_sim/sim_board/dbg_r_nw
add wave -label addr       -radix hex sim:/testbench_motones_sim/sim_board/dbg_addr
add wave -label d_io       -radix hex sim:/testbench_motones_sim/sim_board/dbg_d_io
#add wave -label instruction -radix hex sim:/testbench_motones_sim/sim_board/dbg_instruction


#add wave -divider ce-pins
#add wave -label rom_ce_n sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_x(5)
#add wave -label ram_ce_n sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_x(6)

#add wave -radix hex sim:/testbench_motones_sim/sim_board/dbg_int_d_bus
#add wave -label exec_cycle -radix hex sim:/testbench_motones_sim/sim_board/dbg_exec_cycle
#add wave -label ea_carry   -radix decimal -unsigned  sim:/testbench_motones_sim/sim_board/dbg_ea_carry     
#add wave -label wait_a58_branch_next -radix hex sim:/testbench_motones_sim/sim_board/dbg_wait_a58_branch_next     



#add wave -divider regs
#
#add wave -label pcl  -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_ctrl
#add wave -label pch  -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_mask
#
#add wave -label acc    -radix hex sim:/testbench_motones_sim/sim_board/dbg_acc
#add wave -label sp     -radix hex sim:/testbench_motones_sim/sim_board/dbg_sp
#add wave -label x      -radix hex sim:/testbench_motones_sim/sim_board/dbg_x
#add wave -label y      -radix hex sim:/testbench_motones_sim/sim_board/dbg_y
#add wave -label status -radix hex sim:/testbench_motones_sim/sim_board/dbg_status


add wave -divider ppu
add wave -label ppu_clk    sim:/testbench_motones_sim/sim_board/dbg_ppu_clk
add wave -label ppu_ce_n          sim:/testbench_motones_sim/sim_board/dbg_ppu_ce_n
add wave -label ppu_ctrl  -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_ctrl
add wave -label ppu_mask  -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_mask
add wave -label ppu_status   -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_status
add wave -label ppu_addr -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_addr
add wave -label ppu_data -radix hex sim:/testbench_motones_sim/sim_board/dbg_ppu_data
#add wave -label ppu_scrl_x -radix decimal -unsigned  sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_x
#add wave -label ppu_scrl_y -radix decimal -unsigned  sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_y


add wave -divider vga_pos
add wave -label emu_ppu_clk     sim:/testbench_motones_sim/sim_board/dbg_exec_cycle(3)
add wave -label nes_x           -radix decimal -unsigned  {sim:/testbench_motones_sim/sim_board/dbg_exec_cycle(0) & 
                                                           sim:/testbench_motones_sim/sim_board/dbg_instruction(7 downto 0)}
add wave -label nes_y           -radix decimal -unsigned  {sim:/testbench_motones_sim/sim_board/dbg_exec_cycle(4) & 
                                                           sim:/testbench_motones_sim/sim_board/dbg_status(7 downto 0)}
#add wave -label dbg_disp_nt     -radix hex sim:/testbench_motones_sim/sim_board/dbg_disp_nt
#add wave -label dbg_disp_attr   -radix hex sim:/testbench_motones_sim/sim_board/dbg_disp_attr
#add wave -label dbg_disp_ptn_h  -radix hex sim:/testbench_motones_sim/sim_board/dbg_disp_ptn_h
#add wave -label dbg_disp_ptn_l  -radix hex sim:/testbench_motones_sim/sim_board/dbg_disp_ptn_l

add wave -divider vram
add wave -label ale sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_x(0)
add wave -label rd_n sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_x(1)
add wave -label wr_n sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_x(2)
#add wave -label nt0_ce_n sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_x(3)

add wave  -radix hex -label v_addr  {sim:/testbench_motones_sim/sim_board/dbg_vram_a(13 downto 8) & 
                                     sim:/testbench_motones_sim/sim_board/dbg_vram_ad(7 downto 0)}
add wave  -radix hex -label vram_ad sim:/testbench_motones_sim/sim_board/dbg_vram_ad

#add wave -label plt_ce_n sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_y(5)
#add wave -label plt_r_n sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_y(4)
#add wave -label plt_w_n sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_y(3)
#add wave -label oam_ce_n sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_y(2)
#add wave -label oam_r_n sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_y(1)
#add wave -label oam_w_n sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_y(0)
#add wave  -radix hex -label plt_addr {sim:/testbench_motones_sim/sim_board/dbg_disp_ptn_h(12 downto 8)}
#add wave  -radix hex -label plt_data {sim:/testbench_motones_sim/sim_board/dbg_disp_ptn_h(7 downto 0)}


add wave -divider oam
add wave  -radix hex -label p_oam_addr {sim:/testbench_motones_sim/sim_board/dbg_disp_ptn_l (7 downto 0)}
add wave  -radix hex -label p_oam_data {sim:/testbench_motones_sim/sim_board/dbg_disp_ptn_l (15 downto 8)}
add wave  -radix hex -label s_oam_addr {sim:/testbench_motones_sim/sim_board/dbg_int_d_bus (4 downto 0)}
add wave  -radix hex -label s_oam_data sim:/testbench_motones_sim/sim_board/dbg_ppu_scrl_y

#add wave -divider vga_out
#add wave -label h_sync_n    sim:/testbench_motones_sim/sim_board/v_sync_n
#add wave -label v_sync_n    sim:/testbench_motones_sim/sim_board/h_sync_n
#add wave -label r           -radix hex sim:/testbench_motones_sim/sim_board/r
#add wave -label g           -radix hex sim:/testbench_motones_sim/sim_board/g
#add wave -label b           -radix hex sim:/testbench_motones_sim/sim_board/b


view structure
view signals
#run -all
run 8 us
wave zoom full

#wave zoom range 3339700 ps 5138320 ps

run 120 us
run 200 us
#run 30 us

##wave addcursor 907923400 ps