transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/tools/qt_proj_test5/motonesfpga_common.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/tools/qt_proj_test5/sdram_controller.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/tools/qt_proj_test5/vga.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/tools/qt_proj_test5/alu_test.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/tools/qt_proj_test5/prg_rom.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/tools/qt_proj_test5/cpu_registers.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/tools/qt_proj_test5/clock_divider.vhd}
vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/tools/qt_proj_test5/qt_proj_test5.vhd}

vcom -93 -work work {D:/daisuke/nes/repo/motonesfpga/tools/qt_proj_test5/testbench_qt_proj_test5.vhd}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L cycloneii -L rtl_work -L work -voptargs="ê "  testbench_qt_proj_test5

##add wave *


#add wave  sim:/testbench_qt_proj_test5/base_clk

add wave  sim:/testbench_qt_proj_test5/sim_board/rst_n
#add wave  sim:/testbench_qt_proj_test5/sim_board/dbg_cpu_clk
#add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_addr
#add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_d_io
#add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_instruction
#add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_int_d_bus


add wave -divider dummy_ppu

add wave sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/ppu_clk

add wave -radix decimal -unsigned sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/pos_x
add wave -radix decimal -unsigned sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/pos_y

add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/nes_r
add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/nes_g
add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/ppu_inst/nes_b


add wave -divider vga_out

add wave -radix decimal -unsigned sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/pos_x

#add wave sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/sw_state

add wave -radix decimal -unsigned sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/vga_x
add wave -radix decimal -unsigned sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/nes_x

add wave -radix decimal -unsigned sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/nes_x_old


add wave sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/sr_state




add wave -divider
add wave  sim:/testbench_qt_proj_test5/sim_board/h_sync_n

add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/wbs_adr_i
add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/wbs_dat_i
add wave sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/wbs_we_i
add wave sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/wbs_cyc_i
add wave sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/wbs_tga_i

add wave -divider



add wave -radix decimal -unsigned sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/vga_y
add wave  sim:/testbench_qt_proj_test5/sim_board/v_sync_n


add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/r
add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/g
add wave  -radix hex sim:/testbench_qt_proj_test5/sim_board/b

add wave sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/sdram_clk
#add wave -radix decimal -unsigned sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/mem_cnt

add wave sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/vga_clk

add wave -radix decimal -unsigned sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/count5



#add wave -position end  sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/x_res_n
#add wave -position end  sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/y_res_n
#add wave -position end  sim:/testbench_qt_proj_test5/sim_board/vga_ctl_inst/y_en_n



#add wave -divider status

#add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_d1
#add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_d2
#add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_d_out
#add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_ea_carry
#add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_carry_clr_n
#add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_gate_n



#add wave -divider status_debug

#add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_status
#add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_dec_oe_n
#add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_status_val
#add wave -radix hex sim:/testbench_qt_proj_test5/sim_board/dbg_stat_we_n

view structure
view signals
#run 1 us
run 100 us
#run 20000 us

#1 frame is 16.8 ms
#run 17 ms

wave zoom full

