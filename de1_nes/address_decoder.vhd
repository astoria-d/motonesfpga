library ieee;
use ieee.std_logic_1164.all;

-- this address decoder inserts dummy setup time on write.
entity address_decoder is
generic (abus_size : integer := 16; dbus_size : integer := 8);
    port (
            addr        : in std_logic_vector (abus_size - 1 downto 0);
            rom_ce_n    : out std_logic;
            ram_ce_n    : out std_logic;
            ppu_ce_n    : out std_logic;
            apu_ce_n    : out std_logic
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

begin

    rom_ce_n <= not addr(15);

    ppu_ce_n <= '0'
            when (addr(15) = '0' and addr(14) = '0' and addr(13) = '1')  else
                '1';

    apu_ce_n <= '0'
            when (addr(15) = '0' and addr(14) = '1' and addr(13) = '0')  else
                '1';

    -- ram range : 0 - 0x2000.
    -- 0x2000 is 0010_0000_0000_0000
    ram_ce_n <= '0'
            when ((addr(15) or addr(14) or addr(13)) = '0') else
                '1';

end rtl;



-----------------------------------------------------
-----------------------------------------------------
---------- VRAM / CHR ROM Address Decoder -----------
-----------------------------------------------------
-----------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity v_address_decoder is
generic (abus_size : integer := 14; dbus_size : integer := 8);
    port (
            v_addr      : in std_logic_vector (13 downto 0);
            nt_v_mirror : in std_logic;
            pt_ce_n     : out std_logic;
            nt0_ce_n    : out std_logic;
            nt1_ce_n    : out std_logic
        );
end v_address_decoder;

-- Address      Size    Description
-- $0000-$0FFF  $1000   Pattern Table 0 [lower CHR bank]
-- $1000-$1FFF  $1000   Pattern Table 1 [upper CHR bank]
-- $2000-$23FF  $0400   Name Table #0
-- $2400-$27FF  $0400   Name Table #1
-- $2800-$2BFF  $0400   Name Table #2
-- $2C00-$2FFF  $0400   Name Table #3
-- $3000-$3EFF  $0F00   Mirrors of $2000-$2FFF
-- $3F00-$3F1F  $0020   Palette RAM indexes [not RGB values]
-- $3F20-$3FFF  $0080   Mirrors of $3F00-$3F1F

architecture rtl of v_address_decoder is

begin

    --pattern table
    pt_ce_n <= '0' when (v_addr(13) = '0') else
             '1' ;

    --name table0
    nt0_ce_n <=     '1' when (v_addr(13 downto 8) = "111111") else
                    '0' when (((v_addr(11) or v_addr(10)) = '0') 
                        or (nt_v_mirror = '1' and v_addr(11) = '1' and v_addr(10) = '0')
                        or (nt_v_mirror = '0' and v_addr(11) = '0' and v_addr(10) = '1')) else
                    '1';

    --name table1
    nt1_ce_n <=     '1' when (v_addr(13 downto 8) = "111111") else
                    '0' when (((v_addr(11) and v_addr(10)) = '1') 
                    or (nt_v_mirror = '1' and v_addr(11) = '0' and v_addr(10) = '1')
                    or (nt_v_mirror = '0' and v_addr(11) = '1' and v_addr(10) = '0')) else
                    '1';

end rtl;

