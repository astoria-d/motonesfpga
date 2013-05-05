
library IEEE;
use IEEE.std_logic_1164.all;

entity testbench_fa is
end testbench_fa;

architecture stimulus of testbench_fa is 
    component fa
        port (
                a, b, c : in std_logic;
                s, cout : out std_logic
             );
    end component;
    signal aa, bb, cc, ss, ccout: std_logic;

begin
    dut : fa port map (aa, bb, cc, ss, ccout);

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

    p3 : process
    begin
        cc <= '0'; wait for 40 ns;
        cc <= '1'; wait for 40 ns;
    end process;

end stimulus ;

