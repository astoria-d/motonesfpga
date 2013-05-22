
library IEEE;
use IEEE.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;


entity testbench_cpu_bus is
end testbench_cpu_bus;

architecture stimulus of testbench_cpu_bus is 
    component cpu_bus
    generic (abus_size : integer := 16; dbus_size : integer := 8);
        port (  phi2        : in std_logic;
                R_nW        : in std_logic; 
                addr       : in std_logic_vector (abus_size - 1 downto 0);
                d_in       : in std_logic_vector (dbus_size - 1 downto 0);
                d_out      : out std_logic_vector (dbus_size - 1 downto 0)
    );
    end component;

    constant cpu_clk : time := 589 ns;
    constant size8 : integer := 8;
    constant size16 : integer := 16;

    signal cclk         : std_logic;
    signal rr_nw        : std_logic;
    signal aa16         : std_logic_vector (size16 - 1 downto 0);
    signal dd8_in       : std_logic_vector (size8 - 1 downto 0);
    signal dd8_out      : std_logic_vector (size8 - 1 downto 0);
begin
    dut0 : cpu_bus generic map (size16, size8) 
        port map (cclk, rr_nw, aa16, dd8_in, dd8_out);

    p1 : process
    variable i : integer := 0;
    begin
        cclk <= '1';
        wait for cpu_clk / 2;
        cclk <= '0';
        wait for cpu_clk / 2;
    end process;

    p2 : process
    variable i : integer := 0;
    constant loopcnt : integer := 5;
    begin

        --syncronize with clock dropping edge.
        wait for cpu_clk / 2;

        for i in 0 to loopcnt loop
            dd8_in <= conv_std_logic_vector(i, size8);
            aa16 <= conv_std_logic_vector(i, size16);
            wait for cpu_clk;
        end loop;

        ---read test.
        rr_nw <= '1';
        --ram at 0x0000
        aa16 <= x"0000";
        wait for cpu_clk;
        aa16 <= x"0010";
        wait for cpu_clk;

        --rom at 0x8000
        aa16 <= x"8000";
        wait for cpu_clk;
        aa16 <= x"8001";
        wait for cpu_clk;
        aa16 <= x"ffff";
        wait for cpu_clk;

        --unknown addr at 0x4000
        aa16 <= x"4000";
        wait for cpu_clk;
        aa16 <= x"0010";
        wait for cpu_clk;

        --write test
        rr_nw <= '0';
        for i in 0 to loopcnt loop
            --write to ram
            aa16 <= conv_std_logic_vector(i, size16);
            dd8_in <= conv_std_logic_vector(i, size8);
            wait for cpu_clk;
        end loop;
        rr_nw <= '1';
        for i in 0 to loopcnt loop
            --read ram
            aa16 <= conv_std_logic_vector(i, size16);
            wait for cpu_clk;
        end loop;

        rr_nw <= '0';
        for i in 0 to loopcnt loop
            --write to rom
            aa16 <= conv_std_logic_vector(16#8000# + i, size16);
            dd8_in <= conv_std_logic_vector(i * 10, size8);
            wait for cpu_clk;
            aa16 <= conv_std_logic_vector(16#F000# + i, size16);
            dd8_in <= conv_std_logic_vector(i * 10, size8);
            wait for cpu_clk;
        end loop;

        rr_nw <= '1';
        for i in 0 to loopcnt loop
            --read ram
            aa16 <= conv_std_logic_vector(16#8000# + i, size16);
            wait for cpu_clk;
            aa16 <= conv_std_logic_vector(16#F000# + i, size16);
            wait for cpu_clk;
        end loop;

        rr_nw <= '0';
        for i in 0 to loopcnt loop
            --write to rom
            aa16 <= conv_std_logic_vector(i, size16);
            dd8_in <= conv_std_logic_vector(i ** 2, size8);
            wait for cpu_clk;
        end loop;

        rr_nw <= '1';
        --ram mirror test.
        for i in 0 to loopcnt loop
            --write to rom
            aa16 <= conv_std_logic_vector(16#0000# + i, size16);
            wait for cpu_clk;
            aa16 <= conv_std_logic_vector(16#0800# + i, size16);
            wait for cpu_clk;
            aa16 <= conv_std_logic_vector(16#1000# + i, size16);
            wait for cpu_clk;
            aa16 <= conv_std_logic_vector(16#1800# + i, size16);
            wait for cpu_clk;
            aa16 <= conv_std_logic_vector(16#2000# + i, size16);
            wait for cpu_clk;
            aa16 <= conv_std_logic_vector(16#4000# + i, size16);
            wait for cpu_clk;
            aa16 <= conv_std_logic_vector(16#8000# + i, size16);
            wait for cpu_clk;
        end loop;
        wait for cpu_clk;

        wait;
    end process;

end stimulus ;

