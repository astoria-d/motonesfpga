
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;


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

    p : process
    variable out_line : line;
    variable i,j : integer;
    begin
        for i in 0 to 255 loop
            aa <= conv_std_logic_vector(i, 8);
            for j in 0 to 255 loop

                bb <= conv_std_logic_vector(j, 8);
                write(out_line, string'("test "));
                write(out_line, i);
                write(out_line, string'(", "));
                write(out_line, j);
                writeline(output, out_line);

                wait for 10 ns;
            end loop;

            wait for 10 ns;
        end loop;
    end process;

--    p1 : process
--    begin
--        aa <= "00000000"; wait for 10 ns;
--        aa <= "00000001"; wait for 10 ns;
--    end process;
--
--    p2 : process
--    begin
--        bb <= "00000000"; wait for 20 ns;
--        bb <= "00000001"; wait for 20 ns;
--    end process;

end stimulus ;

