
library IEEE;
use IEEE.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;


entity testbench_alu is
end testbench_alu;

architecture stimulus of testbench_alu is 
    component alu
    port (  a, b, m     : in std_logic_vector (7 downto 0);
            o           : out std_logic_vector (7 downto 0);
            cin         : in std_logic;
            cout        : out std_logic;
            n, v, z     :   out std_logic
        );
    end component;
    signal aa, bb, oo, mm : std_logic_vector (7 downto 0);
    signal ccin, ccout, nn, vv, zz : std_logic;
    constant interval : time := 20 ns;
begin
    dut : alu port map (aa, bb, mm, oo, ccin, ccout, nn, vv, zz);

    --aa <= "00000000";
    --bb <= "00000000";
    --mm <= "00000000";
    --ccin <= '0';

    p : process
    variable out_line : line;
    variable i,j : integer;
    begin
        wait for interval;

        write(out_line, string'("adc test 1"));
        writeline(output, out_line);
        aa <= x"74";
        bb <= x"70";
        mm <= "01100111";
        ccin <= '0';
        wait for interval;

        write(out_line, string'("adc test 2"));
        writeline(output, out_line);
        aa <= x"80";
        bb <= x"84";
        mm <= "01100000";
        ccin <= '0';
        wait for interval;

        write(out_line, string'("adc test 3"));
        writeline(output, out_line);
        aa <= x"a0";
        bb <= x"cf";
        mm <= "01100000";
        ccin <= '0';
        wait for interval;

        write(out_line, string'("test done"));
        writeline(output, out_line);
        wait;
    end process;

end stimulus ;

