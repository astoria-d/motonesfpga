
library IEEE;
use IEEE.std_logic_1164.all;

entity testbench_clock_divider is
end testbench_clock_divider;

architecture stimulus of testbench_clock_divider is 
    component clock_divider
        port (  base_clk    : in std_logic;
                reset_n     : in std_logic;
                cpu_clk     : out std_logic;
                ppu_clk     : out std_logic;
                mem_clk     : out std_logic;
                vga_clk     : out std_logic
            );
    end component;

    ---clock frequency = 21,477,270 (21 MHz)
    ---DE1 clock frequency = 50 MHz
    constant base_clock_time : time := 20 ns;
    constant reset_time : time := 100 ns;

    signal bbase, rreset_n, ccpu, pppu, mmem, vvga : std_logic;

begin
    dut: clock_divider port map (bbase, rreset_n, ccpu, pppu, mmem, vvga);

    clock_p: process
    begin
        bbase <= '1';
        wait for base_clock_time / 2;
        bbase <= '0';
        wait for base_clock_time / 2;
    end process;

    reset_p: process
    begin
        wait for reset_time;
        rreset_n <= '0';

        wait for 100 ns;
        rreset_n <= '1';

        wait for 10 us;
    end process;

end stimulus ;

