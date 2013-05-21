library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;
--use std.textio.all;

----SRAM asyncronous memory.
entity ram is 
    generic (abus_size : integer := 16; dbus_size : integer := 8);
    port (  ce_n, oe_n, we_n  : in std_logic;   --select pin active low.
            addr            : in std_logic_vector (abus_size - 1 downto 0);
            d_in             : in std_logic_vector (dbus_size - 1 downto 0);
            d_out            : out std_logic_vector (dbus_size - 1 downto 0)
        );
end ram;

architecture rtl of ram is

subtype ram_data is std_logic_vector (dbus_size -1 downto 0);
type ram_array is array (0 to 2**abus_size - 1) of ram_data;
--type ram_array is array (0 to 16#0800#) of ram_data;

signal work_ram : ram_array;

begin
    p_write : process (ce_n, we_n, addr, d_in)
    begin
    if (ce_n = '0' and we_n = '0') then
        work_ram(conv_integer(addr)) <= d_in;
    end if;
    end process;

    p_read : process (ce_n, we_n, oe_n, addr)
--    variable out_line : line;
--    variable index : integer;
    begin
    if (ce_n= '0' and we_n = '1' and oe_n = '0') then
        d_out <= work_ram(conv_integer(addr));
--                index := conv_integer(addr);
--                d_out <= work_ram(index);
--
--                write(out_line, index);
--                write(out_line, string'(", "));
--                write(out_line, conv_integer(work_ram(index)));
--                writeline(output, out_line);
    end if;
    end process;
end rtl;

