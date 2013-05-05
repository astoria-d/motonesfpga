
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity testbench_adder8 is
end testbench_adder8;

architecture stimulus of testbench_adder8 is 
    component adder8
        generic (N : integer := 8);
        port (  a, b    : in std_logic_vector (N - 1 downto 0);
                s       : out std_logic_vector (N - 1 downto 0);
                c       : out std_logic
                );
    end component;
    constant N : integer := 8;
    signal aa, bb, ss: std_logic_vector (N-1 downto 0);
    signal cc: std_logic;
begin
    dut : adder8 port map (aa, bb, ss, cc);

    p1 : process
    begin
        aa <= "00000000"; wait for 10 ns;
        aa <= "00000001"; wait for 10 ns;
    end process;

    p2 : process
    begin
        bb <= "00000000"; wait for 20 ns;
        bb <= "00000001"; wait for 20 ns;
    end process;

end stimulus ;

