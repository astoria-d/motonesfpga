library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;
--use std.textio.all;

----SRAM asyncronous memory.
entity ram is 
    generic (abus_size : integer := 16; dbus_size : integer := 8);
    port (  ce_n, oe_n, we_n : in std_logic;   --select pin active low.
            addr             : in std_logic_vector (abus_size - 1 downto 0);
            d_io             : inout std_logic_vector (dbus_size - 1 downto 0)
            --d_in             : in std_logic_vector (dbus_size - 1 downto 0);
            --d_out            : out std_logic_vector (dbus_size - 1 downto 0)
        );
end ram;

architecture rtl of ram is

subtype ram_data is std_logic_vector (dbus_size -1 downto 0);
type ram_array is array (0 to 2**abus_size - 1) of ram_data;
--type ram_array is array (0 to 16#0800#) of ram_data;

signal work_ram : ram_array;

constant RAM_TAOE : time := 25 ns;      --OE access time
constant RAM_TOH : time := 10 ns;       --write data hold time

begin
    p_write : process (ce_n, we_n)
    begin
    if (ce_n = '0' and we_n = '0') then
        work_ram(conv_integer(addr)) <= d_io;
    end if;
    end process;

    p_read : process (ce_n, oe_n, addr)
    begin
    if (ce_n= '0' and we_n = '1' and oe_n = '0') then
        d_io <= work_ram(conv_integer(addr));
    else
        d_io <= (others => 'Z');
    end if;
    end process;
end rtl;

