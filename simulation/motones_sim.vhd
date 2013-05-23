library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;

--  
--   MOTO NES FPGA On GHDL Simulation Environment Virtual Cuicuit Board
--   All of the components are assembled and instanciated on this board.
--  

entity motones_sim is 
    port (  reset_n     : in std_logic
         );
end motones_sim;

architecture rtl of motones_sim is
    component clock_divider
        port (  base_clk    : in std_logic;
                reset_n     : in std_logic;
                cpu_clk     : out std_logic;
                ppu_clk     : out std_logic
            );
    end component;

    ---clock frequency = 21,477,270 (21 MHz)
    constant base_clock_time : time := 46 ns;

    signal base_clk : std_logic;
    signal cpu_clk, ppu_clk : std_logic;

begin

    clock_inst : clock_divider port map 
        (base_clk, reset_n, cpu_clk, ppu_clk);

    --- generate base clock.
    clock_p: process
    begin
        base_clk <= '1';
        wait for base_clock_time / 2;
        base_clk <= '0';
        wait for base_clock_time / 2;
    end process;


end rtl;

