library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;
--use std.textio.all;

entity motones_sim is 
    generic (abus_size : integer := 16; dbus_size : integer := 8);
    port (  ce_n, oe_n, we_n  : in std_logic;   --select pin active low.
            addr            : in std_logic_vector (abus_size - 1 downto 0);
            d_in             : in std_logic_vector (dbus_size - 1 downto 0);
            d_out            : out std_logic_vector (dbus_size - 1 downto 0)
        );
end motones_sim;

architecture rtl of motones_sim is

begin
end rtl;

