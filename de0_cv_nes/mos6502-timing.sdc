create_clock -name pi_base_clk -period 20 [get_ports {pi_base_clk}]
#create_generated_clock -name cpu_clock -source [get_ports {base_clk}] -divide_by 24 -invert [get_registers {clock_divider:clock_inst|cpu_clk_wk}]
#create_generated_clock -name emu_ppu_clock -source [get_ports {base_clk}] -divide_by 4 -invert [get_registers {clock_divider:clock_inst|counter_register:cpu_clk_cnt|d_flip_flop:counter_reg_inst|q[1]}]
