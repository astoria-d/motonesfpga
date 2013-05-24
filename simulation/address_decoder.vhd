library ieee;
use ieee.std_logic_1164.all;

-- this address decoder inserts dummy setup time on write.
entity address_decoder is
generic (abus_size : integer := 16; dbus_size : integer := 8);
    port (  phi2        : in std_logic; --dropping edge syncronized clock.
            R_nW        : in std_logic; -- active high on read / active low on write.
            addr        : in std_logic_vector (abus_size - 1 downto 0);
            d_in        : in std_logic_vector (dbus_size - 1 downto 0);
            d_out       : out std_logic_vector (dbus_size - 1 downto 0)
);
end address_decoder;

--/*
-- * NES memory map
-- * 0x0000   -   0x07FF      RAM
-- * 0x0800   -   0x1FFF      mirror RAM
-- * 0x2000   -   0x2007      I/O PPU
-- * 0x4000   -   0x401F      I/O APU
-- * 0x6000   -   0x7FFF      battery backup ram
-- * 0x8000   -   0xFFFF      PRG-ROM
-- * */

architecture rtl of address_decoder is
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
    constant rom_32k : integer := 15;     --32k = 15 bit width.

    constant CPU_DST : time := 100 ns;    --write data setup time.

    signal rom_ce_n : std_logic;

    signal ram_ce_n : std_logic;
    signal ram_we_n : std_logic;

    signal rom_out : std_logic_vector (dsize - 1 downto 0);
    signal ram_out : std_logic_vector (dsize - 1 downto 0);
begin

    romport : prg_rom generic map (rom_32k, dsize)
            port map (rom_ce_n, addr(rom_32k - 1 downto 0), rom_out);

    ram_we_n <= not R_nW;
    ramport : ram generic map (ram_2k, dsize)
            port map (ram_ce_n, ram_we_n, R_nW, 
                    addr(ram_2k - 1 downto 0), d_in, ram_out);

    d_out <= rom_out when rom_ce_n = '0' else
            ram_out when ram_ce_n = '0' else
            (others => 'Z');

    main_p : process (phi2)
    begin
        -- rom range : 0x8000 - 0x1_0000
        --rom_ce_n <= not addr(rom_32k);
        if (addr(15) = '1' and R_nW = '1')  then
            rom_ce_n <= '0';
        else
            rom_ce_n <= '1';
        end if;

        -- ram range : 0 - 0x2000.
        -- 0x2000 is 0010_0000_0000_0000
        if ((addr(15) or addr(14) or addr(13)) = '1') then
            ram_ce_n <= '1';
        else
            ram_ce_n <= '0';
        end if;
    end process;

end rtl;

