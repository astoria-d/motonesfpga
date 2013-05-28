library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.conv_std_logic_vector;

entity pc is 
    generic (
            dsize : integer := 8;
            reset_addr : integer := 0
            );
    port (  
            trig_clk        : in std_logic;
            res_n           : in std_logic;
            dbus_in_n       : in std_logic;
            dbus_out_n      : in std_logic;
            abus_out_n      : in std_logic;
            int_d_bus       : inout std_logic_vector (dsize - 1 downto 0);
            int_a_bus       : out std_logic_vector (dsize - 1 downto 0)
        );
end pc;

architecture rtl of pc is

signal val : std_logic_vector (dsize - 1 downto 0);

begin
    int_a_bus <= val when abus_out_n = '0' else
                (others => 'Z');
    int_d_bus <= val when (dbus_out_n = '0' and dbus_in_n /= '0') else
                (others => 'Z');

    set_p : process (trig_clk, res_n)
    begin
        if ( trig_clk'event and trig_clk = '1') then
            if (dbus_in_n = '0') then
                val <= int_d_bus;
            end if;
        elsif (res_n'event and res_n = '0') then
            val <= conv_std_logic_vector(reset_addr, dsize);
        end if;
    end process;
end rtl;

