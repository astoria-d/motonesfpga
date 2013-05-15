
library IEEE;
use IEEE.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;


entity testbench_regn is
end testbench_regn;

architecture stimulus of testbench_regn is 
    component regn
        generic (dsize : integer := 8);
        port (  clk, en     : in std_logic;
                r           : in std_logic_vector (dsize - 1 downto 0);
                q           : out std_logic_vector (dsize - 1 downto 0)
            );
    end component;
    constant interval : time := 15 ns;
    constant dsize1 : integer := 1;
    constant dsize8 : integer := 8;
    constant dsize16 : integer := 16;
    signal cclk, een : std_logic;
    signal rr1, qq1    : std_logic_vector (dsize1 - 1 downto 0);
    signal rr8, qq8    : std_logic_vector (dsize8 - 1 downto 0);
    signal rr16, qq16    : std_logic_vector (dsize16 - 1 downto 0);
begin
    dut0 : regn generic map (dsize1) port map (cclk, een, rr1, qq1);
    dut1 : regn generic map (dsize8) port map (cclk, een, rr8, qq8);
    dut2 : regn generic map (dsize16) port map (cclk, een, rr16, qq16);

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
            rr1 <= conv_std_logic_vector(i, dsize1);
            rr8 <= conv_std_logic_vector(i, dsize8);
            rr16 <= conv_std_logic_vector(i, dsize16);
            wait for interval / 4;
        end loop;

        een <= '1';

        for i in 0 to loopcnt * 3 loop
            rr1 <= conv_std_logic_vector(i, dsize1);
            rr8 <= conv_std_logic_vector(i, dsize8);
            rr16 <= conv_std_logic_vector(i, dsize16);
            wait for interval / 3;
        end loop;

        for i in 0 to loopcnt * 4 loop
            rr1 <= conv_std_logic_vector(i, dsize1);
            rr8 <= conv_std_logic_vector(i, dsize8);
            rr16 <= conv_std_logic_vector(i, dsize16);
            wait for interval / 4;
        end loop;

        for i in 0 to loopcnt * 5 loop
            rr1 <= conv_std_logic_vector(i, dsize1);
            rr8 <= conv_std_logic_vector(i, dsize8);
            rr16 <= conv_std_logic_vector(i, dsize16);
            wait for interval / 5;
        end loop;

        for i in 0 to loopcnt * 2 loop
            rr1 <= conv_std_logic_vector(i, dsize1);
            rr8 <= conv_std_logic_vector(i, dsize8);
            rr16 <= conv_std_logic_vector(i, dsize16);
            wait for interval;
        end loop;
        
        for i in 0 to loopcnt * 2 loop
            rr1 <= conv_std_logic_vector(i, dsize1);
            rr8 <= conv_std_logic_vector(i, dsize8);
            rr16 <= conv_std_logic_vector(i, dsize16);
            wait for interval * 2;
        end loop;

        een <= '0';

        for i in 0 to loopcnt * 3 loop
            rr1 <= conv_std_logic_vector(i, dsize1);
            rr8 <= conv_std_logic_vector(i, dsize8);
            rr16 <= conv_std_logic_vector(i, dsize16);
            wait for interval / 3;
        end loop;

        wait;
    end process;

end stimulus ;

