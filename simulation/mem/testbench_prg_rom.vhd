
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;
use std.textio.all;

entity testbench_prg_rom is
end testbench_prg_rom;

architecture stimulus of testbench_prg_rom is 
    component prg_rom
        generic (abus_size : integer := 16; dbus_size : integer := 8);
        port (  clk, ce         : in std_logic;
                addr            : in std_logic_vector (abus_size - 1 downto 0);
                data            : out std_logic_vector (dbus_size - 1 downto 0)
            );
    end component;
    constant interval : time := 15 ns;
    constant dsize : integer := 8;
    --constant asize : integer := 16#8000#;
    constant asize : integer := 15;     --32k rom
    signal cclk, cce : std_logic;
    signal aa       : std_logic_vector (asize - 1 downto 0);
    signal dd       : std_logic_vector (dsize - 1 downto 0);
begin
    dut0 : prg_rom generic map (asize, dsize) port map (cclk, cce, aa, dd);

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
            aa <= conv_std_logic_vector(i, asize);
            wait for interval / 4;
        end loop;

        cce <= '1';

        for i in 0 to loopcnt * 2 loop
            aa <= conv_std_logic_vector(i, asize);
            wait for interval / 2;
        end loop;

        cce <= '0';

        for i in 0 to loopcnt * 2 loop
            aa <= conv_std_logic_vector(i, asize);
            wait for interval / 2;
        end loop;

        wait;
    end process;

end stimulus ;

