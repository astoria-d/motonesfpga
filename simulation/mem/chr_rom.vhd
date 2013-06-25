library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;
use ieee.std_logic_arith.conv_std_logic_vector;
use std.textio.all;

--asyncronous rom
entity chr_rom is 
    generic (abus_size : integer := 13; dbus_size : integer := 8);
    port (  ce_n            : in std_logic;     --active low.
            addr            : in std_logic_vector (abus_size - 1 downto 0);
            data            : out std_logic_vector (dbus_size - 1 downto 0)
        );
end chr_rom;

architecture rtl of chr_rom is

--CHR ROM is 8k
subtype rom_data is std_logic_vector (dbus_size -1 downto 0);
type rom_array is array (0 to 2**abus_size - 1) of rom_data;

--function is called only once at the array initialize.
function rom_fill return rom_array is 
    type binary_file is file of character;
    FILE nes_file : binary_file OPEN read_mode IS "rom-file.nes" ;
    variable read_data : character;
    variable i : integer;
    variable out_line : line;
    variable ret : rom_array;
    begin
        --skip first 16 bit data(NES cardridge header part.)
        for i in 0 to 15 loop
            read(nes_file, read_data);
        end loop;
        --skip program ROM part
        for i in 0 to 16#8000# - 1 loop
            read(nes_file, read_data);
        end loop;

        for i in ret'range loop
            read(nes_file, read_data);
            ret(i) :=
                conv_std_logic_vector(character'pos(read_data), 8);
        end loop;
        write(out_line, string'("chr rom file load success."));
        writeline(output, out_line);
        return ret;
    end rom_fill;

--itinialize with the rom_fill function.
constant p_rom : rom_array := rom_fill;

begin

    p : process (ce_n, addr)
    begin
    if (ce_n = '0') then
        data <= p_rom(conv_integer(addr));
    else
        data <= (others => 'Z');
    end if;
    end process;
end rtl;
