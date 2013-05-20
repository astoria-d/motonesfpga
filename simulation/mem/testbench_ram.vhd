
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;
use std.textio.all;

entity testbench_ram is
end testbench_ram;

architecture stimulus of testbench_ram is 
    component ram
        generic (abus_size : integer := 16; dbus_size : integer := 8);
        port (  clk, ce         : in std_logic;
                oe, we          : in std_logic;
                addr            : in std_logic_vector (abus_size - 1 downto 0);
                din             : in std_logic_vector (dbus_size - 1 downto 0);
                dout            : out std_logic_vector (dbus_size - 1 downto 0)
            );
    end component;
    constant interval : time := 15 ns;
    constant dsize : integer := 8;
    --constant asize : integer := 16#8000#;
    constant asize_2k : integer := 11;
    signal cclk, cce, ooe, wwe : std_logic;
    signal aa       : std_logic_vector (asize_2k - 1 downto 0);
    signal ddin         : std_logic_vector (dsize - 1 downto 0);
    signal ddout        : std_logic_vector (dsize - 1 downto 0);
begin
    dut0 : ram generic map (asize_2k, dsize) 
        port map (cclk, cce, ooe, wwe, aa, ddin, ddout);

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
            aa <= conv_std_logic_vector(i, asize_2k);
            ddin <= conv_std_logic_vector(i, dsize);
            wait for interval / 4;
        end loop;

        cce <= '1';

        for i in 0 to loopcnt * 2 loop
            aa <= conv_std_logic_vector(i, asize_2k);
            ddin <= conv_std_logic_vector(i, dsize);
            wait for interval / 2;
        end loop;

        wwe <= '1';
        ooe <= '0';

        for i in 0 to loopcnt loop
            aa <= conv_std_logic_vector(i, asize_2k);
            ddin <= conv_std_logic_vector(i, dsize);
            wait for interval;
        end loop;

        wwe <= '0';
        ooe <= '1';

        for i in 0 to loopcnt loop
            aa <= conv_std_logic_vector(i, asize_2k);
            wait for interval;
        end loop;

        cce <= '0';

        for i in 0 to loopcnt * 2 loop
            aa <= conv_std_logic_vector(i, asize_2k);
            wait for interval / 2;
        end loop;

        wait;
    end process;

end stimulus ;

