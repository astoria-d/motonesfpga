-------------------------------
-- LS373 transparent D-latch---
-------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity ls373 is 
    generic (
        dsize : integer := 8
    );
    port (  c         : in std_logic;
            we_n      : in std_logic;
            oc_n      : in std_logic;
            d         : in std_logic_vector(dsize - 1 downto 0);
            q         : out std_logic_vector(dsize - 1 downto 0)
    );
end ls373;

architecture rtl of ls373 is
begin
    q <= (others => 'Z');
end rtl;




-------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity ppu is 
    port (  
    signal dbg_ppu_ce_n    : out std_logic;
    signal dbg_ppu_ctrl, dbg_ppu_mask, dbg_ppu_status : out std_logic_vector (7 downto 0);
    signal dbg_ppu_addr : out std_logic_vector (13 downto 0);
    signal dbg_ppu_data, dbg_ppu_scrl_x, dbg_ppu_scrl_y : out std_logic_vector (7 downto 0);

    signal dbg_ppu_clk                      : out std_logic;
    signal dbg_vga_clk                      : out std_logic;
    signal dbg_nes_x                        : out std_logic_vector (8 downto 0);
    signal dbg_vga_x                        : out std_logic_vector (9 downto 0);
    signal dbg_nes_y                        : out std_logic_vector (8 downto 0);
    signal dbg_vga_y                        : out std_logic_vector (9 downto 0);
    signal dbg_disp_nt, dbg_disp_attr       : out std_logic_vector (7 downto 0);
    signal dbg_disp_ptn_h, dbg_disp_ptn_l   : out std_logic_vector (15 downto 0);
    signal dbg_plt_ce_rn_wn                 : out std_logic_vector (2 downto 0);
    signal dbg_plt_addr                     : out std_logic_vector (4 downto 0);
    signal dbg_plt_data                     : out std_logic_vector (7 downto 0);
    signal dbg_p_oam_ce_rn_wn               : out std_logic_vector (2 downto 0);
    signal dbg_p_oam_addr                   : out std_logic_vector (7 downto 0);
    signal dbg_p_oam_data                   : out std_logic_vector (7 downto 0);
    signal dbg_s_oam_ce_rn_wn               : out std_logic_vector (2 downto 0);
    signal dbg_s_oam_addr                   : out std_logic_vector (4 downto 0);
    signal dbg_s_oam_data                   : out std_logic_vector (7 downto 0);
    signal dbg_emu_ppu_clk                  : out std_logic;

    signal dbg_ppu_addr_we_n                : out std_logic;
    signal dbg_ppu_clk_cnt                  : out std_logic_vector(1 downto 0);

    
            ppu_clk     : in std_logic;
            mem_clk     : in std_logic;
            ce_n        : in std_logic;
            rst_n       : in std_logic;
            r_nw        : in std_logic;
            cpu_addr    : in std_logic_vector (2 downto 0);
            cpu_d       : inout std_logic_vector (7 downto 0);

            vblank_n    : out std_logic;
            rd_n        : out std_logic;
            wr_n        : out std_logic;
            ale         : out std_logic;
            vram_ad     : inout std_logic_vector (7 downto 0);
            vram_a      : out std_logic_vector (13 downto 8);

            vga_clk     : in std_logic;
            h_sync_n    : out std_logic;
            v_sync_n    : out std_logic;
            r           : out std_logic_vector(3 downto 0);
            g           : out std_logic_vector(3 downto 0);
            b           : out std_logic_vector(3 downto 0)

    );
end ppu;

architecture rtl of ppu is

begin
    vblank_n    <= 'Z';
    rd_n        <= 'Z';
    wr_n        <= 'Z';
    ale         <= 'Z';
    vram_ad     <= (others => 'Z');
    vram_a      <= (others => 'Z');
    h_sync_n    <= 'Z';
    v_sync_n    <= 'Z';
    r           <= (others => 'Z');
    g           <= (others => 'Z');
    b           <= (others => 'Z');
end rtl;




-------------------------------------
library ieee;
use ieee.std_logic_1164.all;

--asyncronous rom
entity chr_rom is 
    generic (abus_size : integer := 13; dbus_size : integer := 8);
    port (  
            clk             : in std_logic;
            ce_n            : in std_logic;     --active low.
            addr            : in std_logic_vector (abus_size - 1 downto 0);
            data            : out std_logic_vector (dbus_size - 1 downto 0)
        );
end chr_rom;

architecture rtl of chr_rom is
begin
    data     <= (others => 'Z');
end rtl;

