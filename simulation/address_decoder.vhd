library ieee;
use ieee.std_logic_1164.all;

-- this address decoder inserts dummy setup time on write.
entity address_decoder is
generic (abus_size : integer := 16; dbus_size : integer := 8);
    port (  phi2        : in std_logic; --dropping edge syncronized clock.
            mem_clk     : in std_logic;
            R_nW        : in std_logic; -- active high on read / active low on write.
            addr        : in std_logic_vector (abus_size - 1 downto 0);
            d_io        : in std_logic_vector (dbus_size - 1 downto 0);
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

    rom_ce_n <= '0' when (addr(15) = '1' and R_nW = '1') else
             '1' ;

    ppu_ce_n <= '0'
            when (addr(15) = '0' and addr(14) = '0' and addr(13) = '1')  else
                '1';

    apu_ce_n <= '0'
            when (addr(15) = '0' and addr(14) = '1' and addr(13) = '0')  else
                '1';

    --ram io timing.
    main_p : process (phi2, addr, d_io, R_nW)
    begin
            -- ram range : 0 - 0x2000.
            -- 0x2000 is 0010_0000_0000_0000
        if ((addr(15) or addr(14) or addr(13)) = '0') then
        --if (addr < "0010000000000000") then
            if (R_nW = '0') then
                --write
                --write timing slided by half clock.
                ram_ce_n <= not phi2;
            elsif (R_nW = '1') then 
                --read
                ram_ce_n <= '0';
            else
                ram_ce_n <= '1';
            end if;
        else
            ram_ce_n <= '1';
        end if;
    end process;

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
    port (  clk         : in std_logic; 
            rd_n        : in std_logic;
            wr_n        : in std_logic;
            ale         : in std_logic;
            v_addr      : in std_logic_vector (13 downto 0);
            v_data      : in std_logic_vector (7 downto 0);
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
    pt_ce_n <= '0' when (v_addr(13) = '0' and rd_n = '0') else
             '1' ;

    --ram io timing.
    main_p : process (clk, v_addr, v_data, wr_n)
    begin
        if (v_addr(13) = '1') then
            ---name tbl
            if ((v_addr(12) and v_addr(11) and v_addr(10) 
                        and v_addr(9) and v_addr(8)) = '0') then
                if (nt_v_mirror = '1') then
                    --bit 10 is the name table selector.
                    if (v_addr(10) = '0') then
                        --name table 0 enable.
                        nt1_ce_n <= '1';
                        if (wr_n = '0') then
                            --write
                            nt0_ce_n <= clk;
                        elsif (rd_n = '0') then 
                            --read
                            nt0_ce_n <= '0';
                        else
                            nt0_ce_n <= '1';
                        end if;
                    else
                        --name table 1 enable.
                        nt0_ce_n <= '1';
                        if (wr_n = '0') then
                            --write
                            nt1_ce_n <= clk;
                        elsif (rd_n = '0') then 
                            --read
                            nt1_ce_n <= '0';
                        else
                            nt1_ce_n <= '1';
                        end if;
                    end if;
                else
                    --horizontal mirror.
                    --bit 11 is the name table selector.
                    if (v_addr(11) = '0') then
                        --name table 0 enable.
                        nt1_ce_n <= '1';
                        if (wr_n = '0') then
                            --write
                            nt0_ce_n <= clk;
                        elsif (rd_n = '0') then 
                            --read
                            nt0_ce_n <= '0';
                        else
                            nt0_ce_n <= '1';
                        end if;
                    else
                        --name table 1 enable.
                        nt0_ce_n <= '1';
                        if (wr_n = '0') then
                            --write
                            nt1_ce_n <= clk;
                        elsif (rd_n = '0') then 
                            --read
                            nt1_ce_n <= '0';
                        else
                            nt1_ce_n <= '1';
                        end if;
                    end if;
                end if; --if (nt_v_mirror = '1') then
            else
                nt0_ce_n <= '1';
                nt1_ce_n <= '1';
            end if;
        else
            nt0_ce_n <= '1';
            nt1_ce_n <= '1';
        end if; --if (v_addr(13) = '1') then
    end process;

end rtl;

