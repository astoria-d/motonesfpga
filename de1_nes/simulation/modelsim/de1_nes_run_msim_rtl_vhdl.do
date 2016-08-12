
vsim -t 1ps -L lpm -L altera -L altera_mf -L sgate -L cycloneii -L rtl_work -L work testbench_motones_sim


add wave -label rst_n sim:/testbench_motones_sim/sim_board/rst_n;
add wave -label nmi_n sim:/testbench_motones_sim/sim_board/cpu_inst/nmi_n;
add wave -label r_nw sim:/testbench_motones_sim/sim_board/r_nw;
add wave -label cpu_clk sim:/testbench_motones_sim/sim_board/cpu_clk
add wave -label addr -radix hex sim:/testbench_motones_sim/sim_board/addr
add wave -label d_io -radix hex sim:/testbench_motones_sim/sim_board/d_io

add wave -label instruction -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/instruction
add wave -label int_d_bus -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/int_d_bus
add wave -label exec_cycle -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/exec_cycle

add wave -divider regs
add wave -label acc -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/acc/q
add wave -label status_val -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/status_register/status_val
add wave -label sp -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/sp/q
add wave -label x -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/x/q
add wave -label y -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/y/q

add wave -label pcl -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/pcl_inst/q
add wave -label pch -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/pch_inst/q


##add wave -radix hex sim:/testbench_motones_sim/sim_board/cpu_inst/status_reg

#add wave -divider ppu
#add wave  -label cpu_addr -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/cpu_addr
#add wave  -label cpu_d -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/cpu_d
#add wave -label ppu_ce_n sim:/testbench_motones_sim/sim_board/ppu_inst/ce_n
##add wave -label ppu_clk sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_clk
##add wave -label ppu_clk_cnt -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_clk_cnt
#add wave -label ppu_ctl -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_ctrl
#add wave -label ppu_mask -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_mask
#add wave -label ppu_status -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_status
##add wave -label ppu_addr_cnt -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_addr_cnt
##add wave -label ppu_addr_we_n -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_addr_we_n
##add wave -label ppu_addr_in -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_addr_in
##add wave -label ppu_addr_inc1 -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_addr_inc1
##add wave -label ppu_addr_inc32 -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_addr_inc32
#add wave -label ppu_addr -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_addr
#add wave -label ppu_data -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_data
#
#
#add wave -divider ppu_scrl
##add wave -label ppu_ce_n sim:/testbench_motones_sim/sim_board/ppu_inst/ce_n
##add wave -label ppu_clk sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_clk
##add wave -label ppu_scroll_cnt -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_scroll_cnt
##add wave -label ppu_clk_cnt -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_clk_cnt
##
##add wave -label ppu_scroll_cnt_ce_n sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_scroll_cnt_ce_n
##add wave -label ppu_scroll_x_we_n sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_scroll_x_we_n
##add wave -label ppu_scroll_y_we_n sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_scroll_y_we_n
#add wave -label ppu_scr_x -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_scroll_x
#add wave -label ppu_scr_y -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/ppu_scroll_y
#
#
#add wave -divider render
##add wave -label vba_x -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/vga_x
#add wave -label nes_x -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/nes_x
##add wave -label vga_y -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/vga_y
#add wave -label nes_y -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/nes_y
#
#add wave -label ale sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/ale
#add wave -label rd_n sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/rd_n
#add wave -label wr_n sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/wr_n

#add wave -label cur_x -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/ppu_render_inst/cur_x
#add wave -label prf_x -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/ppu_render_inst/prf_x
#add wave -label cur_y -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/ppu_render_inst/cur_y
#add wave -label prf_y -radix decimal -unsigned sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/ppu_render_inst/prf_y
#
#add wave -label disp_nt -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/ppu_render_inst/disp_nt
#add wave -label disp_attr -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/ppu_render_inst/disp_attr
#add wave -label attr_val -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/vga_render_inst/ppu_render_inst/attr_val


#add wave -radix hex sim:/testbench_motones_sim/sim_board/ppu_inst/nes_r \
#sim:/testbench_motones_sim/sim_board/ppu_inst/nes_g \
#sim:/testbench_motones_sim/sim_board/ppu_inst/nes_b

#add wave -label h_sync_n sim:/testbench_motones_sim/sim_board/ppu_inst/h_sync_n
#add wave -label v_sync_n sim:/testbench_motones_sim/sim_board/ppu_inst/v_sync_n



#add wave -divider apu
#add wave  -label cpu_addr sim:/testbench_motones_sim/sim_board/apu_inst/dma_start_n
#add wave  -label dma_next_status -radix hex sim:/testbench_motones_sim/sim_board/apu_inst/dma_next_status
#add wave  -label dma_status -radix hex sim:/testbench_motones_sim/sim_board/apu_inst/dma_status
#add wave  -label dma_cnt_ce sim:/testbench_motones_sim/sim_board/apu_inst/dma_cnt_ce
#add wave  -label rdy sim:/testbench_motones_sim/sim_board/apu_inst/rdy
#add wave  -label dma_write_we_n sim:/testbench_motones_sim/sim_board/apu_inst/dma_write_we_n
#add wave  -label dma_addr -radix hex sim:/testbench_motones_sim/sim_board/apu_inst/dma_addr
#add wave  -label dma_start_n sim:/testbench_motones_sim/sim_board/apu_inst/dma_start_n
#add wave  -label dma_end_n sim:/testbench_motones_sim/sim_board/apu_inst/dma_end_n



view structure
view signals

run 8 us
#run 1000 us
wave zoom full
#run 10000 us


