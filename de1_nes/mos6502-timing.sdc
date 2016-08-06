create_clock -name base_clock -period 20 [get_ports {base_clk}]
create_generated_clock -name cpu_clock -source [get_ports {base_clk}] -divide_by 2 