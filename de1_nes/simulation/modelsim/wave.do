onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /de1_nes/base_clk
add wave -noupdate -format Logic /de1_nes/rst_n
add wave -noupdate -format Logic /de1_nes/dbg_pin0
add wave -noupdate -format Logic /de1_nes/dbg_pin1
add wave -noupdate -format Logic /de1_nes/dbg_pin2
add wave -noupdate -format Logic /de1_nes/dbg_pin3
add wave -noupdate -format Logic /de1_nes/dbg_pin4
add wave -noupdate -format Logic /de1_nes/dbg_pin5
add wave -noupdate -format Logic /de1_nes/dbg_pin6
add wave -noupdate -format Logic /de1_nes/dbg_pin7
add wave -noupdate -format Logic /de1_nes/cpu_clk
add wave -noupdate -format Logic /de1_nes/ppu_clk
add wave -noupdate -format Logic /de1_nes/rdy
add wave -noupdate -format Logic /de1_nes/irq_n
add wave -noupdate -format Logic /de1_nes/nmi_n
add wave -noupdate -format Logic /de1_nes/dbe
add wave -noupdate -format Logic /de1_nes/r_nw
add wave -noupdate -format Logic /de1_nes/phi1
add wave -noupdate -format Logic /de1_nes/phi2
add wave -noupdate -format Literal -radix hexadecimal /de1_nes/addr
add wave -noupdate -format Literal -radix hexadecimal /de1_nes/d_io
add wave -noupdate -format Logic /de1_nes/ppu_ce_n
add wave -noupdate -format Logic /de1_nes/rd_n
add wave -noupdate -format Logic /de1_nes/wr_n
add wave -noupdate -format Logic /de1_nes/ale
add wave -noupdate -format Literal /de1_nes/vram_ad
add wave -noupdate -format Literal /de1_nes/vram_a
add wave -noupdate -format Logic /de1_nes/vga_clk
add wave -noupdate -format Logic /de1_nes/h_sync_n
add wave -noupdate -format Logic /de1_nes/v_sync_n
add wave -noupdate -format Literal /de1_nes/r
add wave -noupdate -format Literal /de1_nes/g
add wave -noupdate -format Literal /de1_nes/b
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {21480 ps} 0}
configure wave -namecolwidth 224
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
update
WaveRestoreZoom {20797 ps} {21708 ps}
