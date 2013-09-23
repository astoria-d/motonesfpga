library ieee;
use ieee.std_logic_1164.all;

-- this address decoder inserts dummy setup time on write.
entity address_decoder is
generic (abus_size : integer := 16; dbus_size : integer := 8);
    port (  phi2        : in std_logic; --dropping edge syncronized clock.
            mem_clk     : in std_logic;
            R_nW        : in std_logic; -- active high on read / active low on write.
            addr        : in std_logic_vector (abus_size - 1 downto 0);
            d_io        : inout std_logic_vector (dbus_size - 1 downto 0);
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
    component ram
        generic (abus_size : integer := 16; dbus_size : integer := 8);
        port (  ce_n, oe_n, we_n  : in std_logic;   --select pin active low.
                addr              : in std_logic_vector (abus_size - 1 downto 0);
                d_io              : inout std_logic_vector (dbus_size - 1 downto 0)
        );
    end component;
    component prg_rom
        generic (abus_size : integer := 15; dbus_size : integer := 8);
        port (
                clk             : in std_logic;
                ce_n            : in std_logic;     --active low.
                addr            : in std_logic_vector (abus_size - 1 downto 0);
                data            : out std_logic_vector (dbus_size - 1 downto 0)
        );
    end component;

    constant dsize : integer := 8;
    constant ram_2k : integer := 11;      --2k = 11 bit width.
    constant rom_32k : integer := 15;     --32k = 15 bit width.
    constant rom_4k : integer := 12;     --4k = 12 bit width.

    constant CPU_DST : time := 100 ns;    --write data setup time.

    signal rom_ce_n : std_logic;
    signal rom_out : std_logic_vector (dsize - 1 downto 0);

    signal ram_ce_n : std_logic;
    signal ram_oe_n : std_logic;
    signal ram_io : std_logic_vector (dsize - 1 downto 0);
    
    
    component single_port_rom
    generic 
    (
        DATA_WIDTH : natural := 8;
        ADDR_WIDTH : natural := 8
    );
    port 
    (
        clk		: in std_logic;
        ce		: in std_logic;
        addr            : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
        q		: out std_logic_vector((DATA_WIDTH -1) downto 0)
    );
end component;

begin

    rom_ce_n <= '0' when (addr(15) = '1' and R_nW = '1') else
             '1' ;

--    romport : prg_rom generic map (rom_32k, dsize)
--            port map (mem_clk, rom_ce_n, addr(rom_32k - 1 downto 0), rom_out);
    --mask address 4k.
    romport : prg_rom generic map (rom_4k, dsize)
            port map (mem_clk, rom_ce_n, addr(rom_4k - 1 downto 0), rom_out);
--    romport : single_port_rom generic map (dsize, rom_4k)
--            port map (mem_clk, rom_ce_n, addr(rom_4k - 1 downto 0), rom_out);

    ram_io <= d_io 
        when (r_nw = '0' and ((addr(15) or addr(14) or addr(13)) = '0')) else
        "ZZZZZZZZ";
    ram_oe_n <= not R_nW;
--    ramport : ram generic map (ram_2k, dsize)
--            port map (ram_ce_n, ram_oe_n, R_nW, 
--                    addr(ram_2k - 1 downto 0), ram_io);

    --must explicitly drive to for inout port.
    d_io <= ram_io 
            when (((addr(15) or addr(14) or addr(13)) = '0') and r_nw = '1')  else
        rom_out 
            when ((addr(15) = '1') and r_nw = '1') else
        (others => 'Z');


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
            vram_ad     : inout std_logic_vector (7 downto 0);
            vram_a      : in std_logic_vector (13 downto 8)
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
    component ram
        generic (abus_size : integer := 16; dbus_size : integer := 8);
        port (  ce_n, oe_n, we_n  : in std_logic;   --select pin active low.
                addr              : in std_logic_vector (abus_size - 1 downto 0);
                d_io              : inout std_logic_vector (dbus_size - 1 downto 0)
        );
    end component;

    component chr_rom
        generic (abus_size : integer := 13; dbus_size : integer := 8);
        port (  ce_n            : in std_logic;     --active low.
                addr            : in std_logic_vector (abus_size - 1 downto 0);
                data            : out std_logic_vector (dbus_size - 1 downto 0);
                nt_v_mirror     : out std_logic
        );
    end component;

    component ls373
        generic (
            dsize : integer := 8
        );
        port (  c         : in std_logic;
                oc_n      : in std_logic;
                d         : in std_logic_vector(dsize - 1 downto 0);
                q         : out std_logic_vector(dsize - 1 downto 0)
        );
    end component;

    constant dsize : integer := 8;
    constant vram_1k : integer := 10;      --2k = 11 bit width.
    constant chr_rom_8k : integer := 13;     --32k = 15 bit width.

    signal v_addr : std_logic_vector (13 downto 0);
    --signal nt_v_mirror2  : std_logic;
    signal nt_v_mirror  : std_logic;

    signal pt_ce_n : std_logic;
    signal nt0_ce_n : std_logic;
    signal nt1_ce_n : std_logic;

begin

    --transparent d-latch
    latch_inst : ls373 generic map (dsize)
                port map(ale, '0', vram_ad, v_addr(7 downto 0));
    v_addr (13 downto 8) <= vram_a;

    --pattern table
    pt_ce_n <= '0' when (v_addr(13) = '0' and rd_n = '0') else
             '1' ;
    --nt_v_mirror <= '0';
    pattern_tbl : chr_rom generic map (chr_rom_8k, dsize)
            port map (pt_ce_n, v_addr(chr_rom_8k - 1 downto 0), vram_ad, nt_v_mirror);

    --name table/attr table
    name_tbl0 : ram generic map (vram_1k, dsize)
            port map (nt0_ce_n, rd_n, wr_n, 
                    v_addr(vram_1k - 1 downto 0), vram_ad);

    name_tbl1 : ram generic map (vram_1k, dsize)
            port map (nt1_ce_n, rd_n, wr_n, 
                    v_addr(vram_1k - 1 downto 0), vram_ad);

    --palette table data is stored in the inside ppu

    --ram io timing.
    main_p : process (clk, v_addr, vram_ad, wr_n)
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

