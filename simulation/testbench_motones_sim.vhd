
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;
use std.textio.all;

entity testbench_motones_sim is
end testbench_motones_sim;

architecture stimulus of testbench_motones_sim is 
    component motones_sim
        port (  rst_n     : in std_logic
             );
    end component;

    signal reset_input : std_logic;
    constant powerup_time : time := 5000 ns;
    constant reset_time : time := 10 us;
begin

    sim_board : motones_sim port map (reset_input);
    --- input reset.
    reset_p: process
    begin
        wait for powerup_time;
        reset_input <= '0';

        wait for reset_time;
        reset_input <= '1';

        wait;
    end process;

end stimulus;

