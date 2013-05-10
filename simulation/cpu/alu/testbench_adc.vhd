
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;


entity testbench_adc is
end testbench_adc;

architecture stimulus of testbench_adc is 
    component adc
    port (  a, b    : in std_logic_vector (7 downto 0);
            sum       : out std_logic_vector (7 downto 0);
            cin         : in std_logic;
            cout        : out std_logic;
            n, v, z : out std_logic
            );
    end component;
    signal aa, bb, ssum: std_logic_vector (7 downto 0);
    signal ccin, ccout, nn, vv, zz : std_logic;
begin
    dut : adc port map (aa, bb, ssum, ccin, ccout, nn, vv, zz);
    ccin <= '0';

    p : process
    variable out_line : line;
    variable i,j : integer;
    begin
        for i in 0 to 255 loop
            aa <= conv_std_logic_vector(i, 8);
            --aa <= i;
            for j in 0 to 255 loop

                bb <= conv_std_logic_vector(j, 8);
                --bb <= j;
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

end stimulus ;

