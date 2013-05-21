library ieee;
use ieee.std_logic_1164.all;

entity cpu_bus is
generic (abus_size : integer := 16; dbus_size : integer := 8);
    port (  oe_n, rw_n      : in std_logic;
            addr            : in std_logic_vector (abus_size - 1 downto 0);
            d_in            : in std_logic_vector (dbus_size - 1 downto 0);
            d_out           : out std_logic_vector (dbus_size - 1 downto 0)
);
end cpu_bus;

--/*
-- * NES memory map
-- * 0x0000   -   0x07FF      RAM
-- * 0x0800   -   0x1FFF      mirror RAM
-- * 0x2000   -   0x2007      I/O PPU
-- * 0x4000   -   0x401F      I/O APU
-- * 0x6000   -   0x7FFF      battery backup ram
-- * 0x8000   -   0xFFFF      PRG-ROM
-- * */

architecture rtl of cpu_bus is
    component ram
        generic (abus_size : integer := 16; dbus_size : integer := 8);
        port (  ce_n, oe_n, we_n  : in std_logic;   --select pin active low.
                addr              : in std_logic_vector (abus_size - 1 downto 0);
                d_in              : in std_logic_vector (dbus_size - 1 downto 0);
                d_out             : out std_logic_vector (dbus_size - 1 downto 0)
        );
    end component;
    component prg_rom
        generic (abus_size : integer := 15; dbus_size : integer := 8);
        port (  ce_n            : in std_logic;     --active low.
                addr            : in std_logic_vector (abus_size - 1 downto 0);
                data            : out std_logic_vector (dbus_size - 1 downto 0)
        );
    end component;

    constant dsize : integer := 8;
    constant ram_2k : integer := 11;      --2k = 11 bit width.
    constant rom_32k : integer := 15;      --2k = 11 bit width.

    signal rom_ce_n : std_logic;
    signal ram_ce_n : std_logic;
    signal rom_out : std_logic_vector (dsize - 1 downto 0);
    signal ram_out : std_logic_vector (dsize - 1 downto 0);
begin

    --rom_ce_n <= not addr(rom_32k);
    rom_ce_n <= '0' when (addr(15) = '1' and oe_n = '0') else
                '1';

    ---0x2000 >> 0010_0000_0000_0000
    ram_ce_n <= '1' when ((addr(15) or addr(14) or addr(13)) = '1') else
                '0';

    romport : prg_rom generic map (rom_32k, dsize)
            port map (rom_ce_n, addr(rom_32k - 1 downto 0), rom_out);

    ramport : ram generic map (ram_2k, dsize)
            port map (ram_ce_n, oe_n, rw_n, 
                    addr(ram_2k - 1 downto 0), d_in, ram_out);

    d_out <= rom_out when rom_ce_n = '0' else
            ram_out when ram_ce_n = '0' else
            (others => 'Z');
end rtl;

