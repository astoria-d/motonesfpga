
set sigs [list]

lappend sigs "sim_board.rst_n"
lappend sigs "sim_board.cpu_clk"
lappend sigs "sim_board.ppu_clk"
lappend sigs "sim_board.vga_clk"
lappend sigs "sim_board.mem_clk"

#add wave -divider cpu/io
lappend sigs "sim_board.r_nw"
lappend sigs "sim_board.addr"
lappend sigs "sim_board.d_io"

#add wave -divider ce-pins
lappend sigs "sim_board.rom_ce_n"
lappend sigs "sim_board.ram_ce_n"
lappend sigs "sim_board.ppu_ce_n"
#add wave -divider ppu
lappend sigs "sim_board.ppu_inst.ppu_ctrl"
lappend sigs "sim_board.ppu_inst.ppu_mask"
lappend sigs "sim_board.ppu_inst.ppu_status"

#add wave -divider vga_pos
lappend sigs "sim_board.ppu_inst.render_inst.cur_x"
lappend sigs "sim_board.ppu_inst.render_inst.cur_y"
lappend sigs "sim_board.ppu_inst.render_inst.disp_nt"
lappend sigs "sim_board.ppu_inst.render_inst.disp_attr"

#add wave -divider vram
lappend sigs "sim_board.mem_clk"
lappend sigs "sim_board.ppu_clk"
lappend sigs "sim_board.ale"
lappend sigs "sim_board.rd_n"
lappend sigs "sim_board.wr_n"
lappend sigs "sim_board.nt0_ce_n"

lappend sigs "sim_board.v_addr"
lappend sigs "sim_board.vram_ad"

lappend sigs "sim_board.ppu_inst.render_inst.plt_ram_ce_n"
lappend sigs "sim_board.ppu_inst.render_inst.plt_r_n"
lappend sigs "sim_board.ppu_inst.render_inst.plt_w_n"
lappend sigs "sim_board.ppu_inst.render_inst.plt_addr"
lappend sigs "sim_board.ppu_inst.render_inst.plt_data"

#add wave -divider vga_out
lappend sigs "sim_board.h_sync_n"
lappend sigs "sim_board.v_sync_n"
lappend sigs "sim_board.r"
lappend sigs "sim_board.g"
lappend sigs "sim_board.b"



set added [ gtkwave::addSignalsFromList $sigs ]

#gtkwave::setZoomFactor 100


