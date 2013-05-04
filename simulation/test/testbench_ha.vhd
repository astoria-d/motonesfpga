
library IEEE;
use IEEE.std_logic_1164.all;

entity testbench_ha is
end testbench_ha;

architecture stimulus of testbench_ha is 
component HA
    port (
            A, B : in std_logic;
            S, C : out std_logic
         );
end component;
signal AA, BB, SS, CC : std_logic;
begin
    dut : ha port map (aa, bb, ss, cc);

p1 : process
begin
    aa <= '0'; wait for 10 ns;
    aa <= '1'; wait for 10 ns;
end process;

p2 : process
begin
    bb <= '0'; wait for 20 ns;
    bb <= '1'; wait for 20 ns;
end process;
end stimulus ;

