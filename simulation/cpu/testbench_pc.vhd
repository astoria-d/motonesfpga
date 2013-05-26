
library IEEE;
use IEEE.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;


entity testbench_pc is
end testbench_pc;

architecture stimulus of testbench_pc is 
    component pc
        generic (dsize : integer := 8);
        port (  trig_clk    : in std_logic;
                dbus_in_n       : in std_logic;
                dbus_out_n      : in std_logic;
                abus_out_n      : in std_logic;
                int_d_bus       : inout std_logic_vector (dsize - 1 downto 0);
                int_a_bus       : out std_logic_vector (dsize - 1 downto 0)
            );
    end component;

    constant interval : time := 15 ns;
    constant dsize8 : integer := 8;
    signal cclk: std_logic;
    signal dbus_in_n: std_logic;
    signal dbus_out_n: std_logic;
    signal abus_out_n: std_logic;

    signal id_bus, ia_bus    : std_logic_vector (dsize8 - 1 downto 0);

begin
    dut1 : pc generic map (dsize8) port map (cclk, dbus_in_n, dbus_out_n, abus_out_n, 
            id_bus, ia_bus);

    p1 : process
    begin

        cclk <= '1';
        wait for interval / 2;
        cclk <= '0';
        wait for interval / 2;
    end process;

    p2 : process
    variable i : integer := 0;
    constant loopcnt : integer := 5;
    begin

        abus_out_n <= '1';
        dbus_in_n <= '1';
        dbus_out_n <= '1';

        --set value.
        id_bus <= conv_std_logic_vector(10, dsize8);
        wait for interval;
        dbus_in_n <= '0';
        wait for interval;

        dbus_in_n <= '1';
        dbus_out_n <= '0';
        wait for interval;

        dbus_out_n <= '1';
        abus_out_n <= '0';
        wait for interval;

        abus_out_n <= '1';
        id_bus <= conv_std_logic_vector(100, dsize8);
        wait for interval;
        abus_out_n <= '0';
        wait for interval;
        abus_out_n <= '1';

        id_bus <= (others => 'Z');
        dbus_out_n <= '0';
        wait for interval;
        dbus_out_n <= '1';

        wait;
    end process;

end stimulus ;

