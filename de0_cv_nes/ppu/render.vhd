-------------------------------------------------------------
-------------------------------------------------------------
------------------- PPU VGA Output Control ------------------
-------------------------------------------------------------
-------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;
use ieee.std_logic_arith.conv_std_logic_vector;
use ieee.std_logic_unsigned.all;

entity render is 
    port (
        pi_rst_n       : in std_logic;
        pi_base_clk    : in std_logic;
        pi_rnd_en      : in std_logic_vector (3 downto 0);

        --ppu i/f
        pi_ppu_ctrl        : in std_logic_vector (7 downto 0);
        pi_ppu_mask        : in std_logic_vector (7 downto 0);
        po_ppu_status      : out std_logic_vector (7 downto 0);
        pi_ppu_scroll_x    : in std_logic_vector (7 downto 0);
        pi_ppu_scroll_y    : in std_logic_vector (7 downto 0);

        --vram i/f
        po_rd_n         : out std_logic;
        po_wr_n         : out std_logic;
        po_v_addr       : out std_logic_vector (13 downto 0);
        io_v_data       : in std_logic_vector (7 downto 0);

        --sprite i/f
        po_spr_ce_n     : out std_logic;
        po_spr_rd_n     : out std_logic;
        po_spr_wr_n     : out std_logic;
        po_spr_addr     : out std_logic_vector (7 downto 0);
        pi_spr_data     : in std_logic_vector (7 downto 0);

        --vga output
        po_h_sync_n    : out std_logic;
        po_v_sync_n    : out std_logic;
        po_r           : out std_logic_vector(3 downto 0);
        po_g           : out std_logic_vector(3 downto 0);
        po_b           : out std_logic_vector(3 downto 0)
        );
end render;

architecture rtl of render is


--------- VGA screen constant -----------
constant VGA_W          : integer := 640;
constant VGA_H          : integer := 480;
constant VGA_W_MAX      : integer := 800;
constant VGA_H_MAX      : integer := 525;
constant H_SP           : integer := 95;
constant H_BP           : integer := 48;
constant H_FP           : integer := 15;
constant V_SP           : integer := 2;
constant V_BP           : integer := 33;
constant V_FP           : integer := 10;

--nes screen size is emulated to align with the vga timing...
constant HSCAN                  : integer := 256;
constant VSCAN                  : integer := 240;
constant HSCAN_NEXT_START       : integer := 382;
constant VSCAN_NEXT_START       : integer := 262;
constant HSCAN_SPR_MAX          : integer := 321;
constant HSCAN_OAM_EVA_START    : integer := 64;

constant PPUBNA    : integer := 1;  --base name address
constant PPUVAI    : integer := 2;  --vram address increment
constant PPUSPA    : integer := 3;  --sprite pattern table address
constant PPUBPA    : integer := 4;  --background pattern table address
constant PPUSPS    : integer := 5;  --sprite size
constant PPUMS     : integer := 6;  --ppu master/slave
constant PPUNEN    : integer := 7;  --nmi enable

constant PPUGS     : integer := 0;  --grayscale
constant PPUSBL    : integer := 1;  --show 8 left most bg pixel
constant PPUSSL    : integer := 2;  --show 8 left most sprite pixel
constant PPUSBG    : integer := 3;  --show bg
constant PPUSSP    : integer := 4;  --show sprie
constant PPUIR     : integer := 5;  --intensify red
constant PPUIG     : integer := 6;  --intensify green
constant PPUIB     : integer := 7;  --intensify blue

constant SPRHFL     : integer := 6;  --flip sprigte horizontally
constant SPRVFL     : integer := 7;  --flip sprigte vertically

constant ST_BSY     : integer := 4;  --vram busy
constant ST_SOF     : integer := 5;  --sprite overflow
constant ST_SP0     : integer := 6;  --sprite 0 hits
constant ST_VBL     : integer := 7;  --vblank


subtype nes_color_data  is std_logic_vector (11 downto 0);
type nes_color_array    is array (0 to 63) of nes_color_data;
--ref: http://hlc6502.web.fc2.com/NesPal2.htm
constant nes_color_palette : nes_color_array := (
        conv_std_logic_vector(16#777#, 12), 
        conv_std_logic_vector(16#20b#, 12), 
        conv_std_logic_vector(16#20b#, 12), 
        conv_std_logic_vector(16#61a#, 12), 
        conv_std_logic_vector(16#927#, 12), 
        conv_std_logic_vector(16#b13#, 12), 
        conv_std_logic_vector(16#a30#, 12), 
        conv_std_logic_vector(16#740#, 12), 
        conv_std_logic_vector(16#450#, 12), 
        conv_std_logic_vector(16#360#, 12), 
        conv_std_logic_vector(16#360#, 12), 
        conv_std_logic_vector(16#364#, 12), 
        conv_std_logic_vector(16#358#, 12), 
        conv_std_logic_vector(16#000#, 12), 
        conv_std_logic_vector(16#000#, 12), 
        conv_std_logic_vector(16#000#, 12),
        conv_std_logic_vector(16#bbb#, 12), 
        conv_std_logic_vector(16#46f#, 12), 
        conv_std_logic_vector(16#44f#, 12), 
        conv_std_logic_vector(16#94f#, 12), 
        conv_std_logic_vector(16#d4c#, 12), 
        conv_std_logic_vector(16#d46#, 12), 
        conv_std_logic_vector(16#e50#, 12), 
        conv_std_logic_vector(16#c70#, 12), 
        conv_std_logic_vector(16#880#, 12), 
        conv_std_logic_vector(16#5a0#, 12), 
        conv_std_logic_vector(16#4a1#, 12), 
        conv_std_logic_vector(16#4a6#, 12), 
        conv_std_logic_vector(16#49c#, 12), 
        conv_std_logic_vector(16#000#, 12), 
        conv_std_logic_vector(16#000#, 12), 
        conv_std_logic_vector(16#000#, 12),
        conv_std_logic_vector(16#fff#, 12), 
        conv_std_logic_vector(16#6af#, 12), 
        conv_std_logic_vector(16#58f#, 12), 
        conv_std_logic_vector(16#a7f#, 12), 
        conv_std_logic_vector(16#f6f#, 12), 
        conv_std_logic_vector(16#f6b#, 12), 
        conv_std_logic_vector(16#f73#, 12), 
        conv_std_logic_vector(16#fa0#, 12), 
        conv_std_logic_vector(16#ed2#, 12), 
        conv_std_logic_vector(16#9e0#, 12), 
        conv_std_logic_vector(16#7f4#, 12), 
        conv_std_logic_vector(16#7e9#, 12), 
        conv_std_logic_vector(16#6de#, 12), 
        conv_std_logic_vector(16#777#, 12), 
        conv_std_logic_vector(16#000#, 12), 
        conv_std_logic_vector(16#000#, 12),
        conv_std_logic_vector(16#fff#, 12), 
        conv_std_logic_vector(16#9df#, 12), 
        conv_std_logic_vector(16#abf#, 12), 
        conv_std_logic_vector(16#cbf#, 12), 
        conv_std_logic_vector(16#ebf#, 12), 
        conv_std_logic_vector(16#fbe#, 12), 
        conv_std_logic_vector(16#fcb#, 12), 
        conv_std_logic_vector(16#fda#, 12), 
        conv_std_logic_vector(16#ff9#, 12), 
        conv_std_logic_vector(16#cf8#, 12), 
        conv_std_logic_vector(16#afa#, 12), 
        conv_std_logic_vector(16#afc#, 12), 
        conv_std_logic_vector(16#aff#, 12), 
        conv_std_logic_vector(16#aaa#, 12), 
        conv_std_logic_vector(16#000#, 12), 
        conv_std_logic_vector(16#000#, 12)
        );

signal reg_vga_x        : integer range 0 to VGA_W_MAX - 1;
signal reg_vga_y        : integer range 0 to VGA_H_MAX - 1;

signal reg_nes_x        : integer range 0 to VGA_W_MAX / 2 - 1;
signal reg_nes_y        : integer range 0 to VGA_W_MAX / 2 - 1;

begin

    --position and sync signal generate.
    pos_p : process (pi_rst_n, pi_base_clk)
    begin
        if (pi_rst_n = '0') then
            reg_vga_x <= 0;
            reg_vga_y <= 0;
            reg_nes_x <= 0;
            reg_nes_y <= 0;
        elsif (rising_edge(pi_base_clk)) then

            reg_nes_x <= reg_vga_x / 2;
            reg_nes_y <= reg_vga_y / 2;

            if ((pi_rnd_en(0) or pi_rnd_en(2))= '1') then
                if (reg_vga_x = VGA_W_MAX - 1) then
                    reg_vga_x <= 0;
                    if (reg_vga_x = VGA_H_MAX - 1) then
                        reg_vga_y <= 0;
                    else
                        reg_vga_y <= reg_vga_y + 1;
                    end if;
                else
                    reg_vga_x <= reg_vga_x + 1;
                end if;
                
                --sync signal assert.
                if (reg_vga_x >= VGA_W + H_FP and reg_vga_x < VGA_W + H_FP + H_SP) then
                    po_h_sync_n <= '0';
                else
                    po_h_sync_n <= '1';
                end if;

                if (reg_vga_y >= VGA_H + V_FP and reg_vga_y < VGA_H + V_FP + V_SP) then
                    po_v_sync_n <= '0';
                else
                    po_v_sync_n <= '1';
                end if;
                
            end if;--if (pi_rnd_en(1) = '1' or pi_rnd_en(3) = '1' ) then
        end if;--if (pi_rst_n = '0') then
    end process;


end rtl;

