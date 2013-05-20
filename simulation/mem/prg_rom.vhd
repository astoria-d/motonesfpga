library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;

entity prg_rom is 
    generic (abus_size : integer := 15; dbus_size : integer := 8);
    port (  clk, ce         : in std_logic;
            addr            : in std_logic_vector (abus_size - 1 downto 0);
            data            : out std_logic_vector (dbus_size - 1 downto 0)
        );
end prg_rom;

architecture rtl of prg_rom is

subtype rom_data is std_logic_vector (dbus_size -1 downto 0);
type rom_array is array (0 to 2**abus_size - 1) of rom_data;

constant p_rom : rom_array := rom_array'(
        x"01",
        x"02",
        x"03",
        x"04",
        x"a1",
        x"b1",
        x"c1",
        x"d1",
        x"ff",
        x"aa",
        x"11",
        others=>x"00"
        );

begin
    p : process (clk, ce, addr)
    begin
    if (clk'event and clk = '1') then
        if (ce = '1') then
           data <= p_rom(conv_integer(addr));
        end if;
    end if;
    end process;
end rtl;

