library ieee;
use ieee.std_logic_1164.all;

entity ppu is 
    port (  clk         : in std_logic;
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

component ppu_render
    port (  clk         : in std_logic;
            rst_n       : in std_logic;
            vblank_n    : out std_logic;
            rd_n        : out std_logic;
            wr_n        : out std_logic;
            ale         : out std_logic;
            vram_ad     : inout std_logic_vector (7 downto 0);
            vram_a      : out std_logic_vector (13 downto 8);
            plt_bus_ce_n : in std_logic;
            plt_r_nw    : in std_logic;
            plt_addr    : in std_logic_vector (4 downto 0);
            plt_data    : inout std_logic_vector (7 downto 0);
            pos_x       : out std_logic_vector (8 downto 0);
            pos_y       : out std_logic_vector (8 downto 0);
            r           : out std_logic_vector (3 downto 0);
            g           : out std_logic_vector (3 downto 0);
            b           : out std_logic_vector (3 downto 0)
    );
end component;

component vga_ctl
    port (  ppu_clk     : in std_logic;
            vga_clk     : in std_logic;
            rst_n       : in std_logic;
            pos_x       : in std_logic_vector (8 downto 0);
            pos_y       : in std_logic_vector (8 downto 0);
            nes_r       : in std_logic_vector (3 downto 0);
            nes_g       : in std_logic_vector (3 downto 0);
            nes_b       : in std_logic_vector (3 downto 0);
            h_sync_n    : out std_logic;
            v_sync_n    : out std_logic;
            r           : out std_logic_vector(3 downto 0);
            g           : out std_logic_vector(3 downto 0);
            b           : out std_logic_vector(3 downto 0)
    );
end component;

signal pos_x       : std_logic_vector (8 downto 0);
signal pos_y       : std_logic_vector (8 downto 0);
signal nes_r       : std_logic_vector (3 downto 0);
signal nes_g       : std_logic_vector (3 downto 0);
signal nes_b       : std_logic_vector (3 downto 0);

signal plt_bus_ce_n : std_logic;
signal plt_r_nw    : std_logic;
signal plt_addr    : std_logic_vector (4 downto 0);
signal plt_data    : std_logic_vector (7 downto 0);

begin


    ---TODO: for the time being...
    plt_bus_ce_n <= 'Z';
    plt_r_nw <= 'Z';
    plt_addr <= (others => 'Z');
    plt_data <= (others => 'Z');

    render_inst : ppu_render port map (clk, rst_n, vblank_n, 
            rd_n, wr_n, ale, vram_ad, vram_a,
            plt_bus_ce_n, plt_r_nw, plt_addr, plt_data,
            pos_x, pos_y, nes_r, nes_g, nes_b);

    vga_inst : vga_ctl port map (clk, vga_clk, rst_n, 
            pos_x, pos_y, nes_r, nes_g, nes_b,
            h_sync_n, v_sync_n, r, g, b);
end rtl;

