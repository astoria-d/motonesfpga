
library IEEE;
use IEEE.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;


entity testbench_data_latch is
end testbench_data_latch;

architecture stimulus of testbench_data_latch is 
    component data_latch
        generic (dsize : integer := 8);
        port (  clk, en     : in std_logic;
                d           : in std_logic_vector (dsize - 1 downto 0);
                q           : out std_logic_vector (dsize - 1 downto 0)
            );
    end component;
    constant interval : time := 15 ns;
    constant dsize8 : integer := 8;
    signal cclk, een : std_logic;
    signal dd8, qq8    : std_logic_vector (dsize8 - 1 downto 0);
begin
    dut1 : data_latch generic map (dsize8) port map (cclk, een, dd8, qq8);

    p1 : process
    variable i : integer := 0;
    constant loopcnt : integer := 10;
    begin

        for i in 0 to loopcnt * 2 loop
            cclk <= '1';
            wait for interval / 2;
            cclk <= '0';
            wait for interval / 2;
        end loop;
    end process;

    p2 : process
    variable i : integer := 0;
    constant loopcnt : integer := 5;
    begin

        wait for interval / 4;

        for i in 0 to loopcnt loop
            dd8 <= conv_std_logic_vector(i, dsize8);
            wait for interval / 4;
        end loop;

        een <= '1';

        for i in 0 to loopcnt * 3 loop
            dd8 <= conv_std_logic_vector(i, dsize8);
            wait for interval / 3;
        end loop;

        een <= '0';

        for i in 0 to loopcnt * 3 loop
            dd8 <= conv_std_logic_vector(i, dsize8);
            wait for interval / 3;
        end loop;

        wait;
    end process;

end stimulus ;

