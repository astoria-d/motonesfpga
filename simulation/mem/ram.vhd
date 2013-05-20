library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;
--use std.textio.all;

entity ram is 
    generic (abus_size : integer := 16; dbus_size : integer := 8);
    port (  clk, ce         : in std_logic;
            oe, we          : in std_logic;
            addr            : in std_logic_vector (abus_size - 1 downto 0);
            din             : in std_logic_vector (dbus_size - 1 downto 0);
            dout            : out std_logic_vector (dbus_size - 1 downto 0)
        );
end ram;

architecture rtl of ram is

subtype ram_data is std_logic_vector (dbus_size -1 downto 0);
type ram_array is array (0 to 2**abus_size) of ram_data;
--type ram_array is array (0 to 16#0800#) of ram_data;

signal work_ram : ram_array;

begin
    p_write : process (clk, ce, we, addr, din)
    begin
    if (clk'event and clk = '1') then
        if (ce = '1') then
            if (we = '1') then
                work_ram(conv_integer(addr)) <= din;
            end if;
        end if;
    end if;
    end process;

    p_read : process (clk, ce, oe, addr)
--    variable out_line : line;
--    variable index : integer;
    begin
    if (clk'event and clk = '1') then
        if (ce = '1') then
            if (oe = '1') then
                dout <= work_ram(conv_integer(addr));
--                index := conv_integer(addr);
--                dout <= work_ram(index);
--
--                write(out_line, index);
--                write(out_line, string'(", "));
--                write(out_line, conv_integer(work_ram(index)));
--                writeline(output, out_line);
            end if;
        end if;
    end if;
    end process;
end rtl;

