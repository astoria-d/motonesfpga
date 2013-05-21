
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;
use std.textio.all;

entity testbench_prg_rom is
end testbench_prg_rom;

architecture stimulus of testbench_prg_rom is 
    component prg_rom
        generic (abus_size : integer := 16; dbus_size : integer := 8);
        port (  ce_n            : in std_logic;     --active low.
                addr            : in std_logic_vector (abus_size - 1 downto 0);
                data            : out std_logic_vector (dbus_size - 1 downto 0)
            );
    end component;
    constant interval : time := 15 ns;
    constant dsize : integer := 8;
    --constant asize : integer := 16#8000#;
    constant asize : integer := 15;     --32k rom
    signal cce_n : std_logic;
    signal aa       : std_logic_vector (asize - 1 downto 0);
    signal dd       : std_logic_vector (dsize - 1 downto 0);
begin
    dut0 : prg_rom generic map (asize, dsize) port map (cce_n, aa, dd);

    p : process
    variable i : integer := 0;
    constant loopcnt : integer := 5;
    begin

        wait for interval / 4;

        for i in 0 to loopcnt loop
            aa <= conv_std_logic_vector(i, asize);
            wait for interval / 4;
        end loop;

        cce_n <= '0';

        for i in 0 to loopcnt * 2 loop
            aa <= conv_std_logic_vector(i, asize);
            wait for interval / 2;
        end loop;

        cce_n <= '1';

        for i in 0 to loopcnt * 2 loop
            aa <= conv_std_logic_vector(i, asize);
            wait for interval / 2;
        end loop;

        cce_n <= '0';
        aa <= conv_std_logic_vector(16#8000#, asize);
        wait for interval / 2;
        aa <= conv_std_logic_vector(16#8000# - 1, asize);
        wait for interval / 2;
        aa <= conv_std_logic_vector(16#8000# / 2, asize);
        wait for interval / 2;

        wait;
    end process;

end stimulus ;

