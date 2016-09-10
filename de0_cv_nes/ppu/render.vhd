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
        pi_v_data       : in std_logic_vector (7 downto 0);

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

constant PREFETCH_INT           : integer := 16;

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
--prefech is wider by scroll reg size.
signal reg_prf_x        : integer range 0 to VGA_W_MAX / 2 + 256 - 1;
signal reg_prf_y        : integer range 0 to VGA_W_MAX / 2 + 256 - 1;

type vac_state is (
    IDLE,
    AD_SET0,
    AD_SET1,
    AD_SET2,
    AD_SET3,
    REG_SET0,
    REG_SET1,
    REG_SET2,
    REG_SET3
    );

signal reg_v_cur_state      : vac_state;
signal reg_v_next_state     : vac_state;

signal reg_v_rd_n       : std_logic;
signal reg_v_wr_n       : std_logic;
signal reg_v_addr       : std_logic_vector (13 downto 0);
signal reg_v_data       : std_logic_vector (7 downto 0);

signal reg_disp_nt          : std_logic_vector (7 downto 0);
signal reg_disp_attr        : std_logic_vector (7 downto 0);
signal reg_disp_ptn_l       : std_logic_vector (15 downto 0);
signal reg_disp_ptn_h       : std_logic_vector (15 downto 0);

begin

    --position and sync signal generate.
    pos_p : process (pi_rst_n, pi_base_clk)
    begin
        if (pi_rst_n = '0') then
            reg_vga_x <= 0;
            reg_vga_y <= 0;
            reg_nes_x <= 0;
            reg_nes_y <= 0;
            reg_prf_x <= 0;
            reg_prf_y <= 0;
        elsif (rising_edge(pi_base_clk)) then
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

            --nes x/y position...
            reg_nes_x <= reg_vga_x / 2;
            reg_nes_y <= reg_vga_y / 2;

            --pre-fetch x/y position...
            if (reg_vga_x < HSCAN_NEXT_START * 2) then
                reg_prf_x <= reg_vga_x / 2 + conv_integer(pi_ppu_scroll_x) + PREFETCH_INT;
            else
                reg_prf_x <= reg_vga_x / 2 + conv_integer(pi_ppu_scroll_x)
                                - HSCAN_NEXT_START + PREFETCH_INT;
            end if;

            if (reg_vga_y < VSCAN * 2) then
                if (reg_vga_x < HSCAN_NEXT_START * 2) then
                    reg_prf_y <= reg_vga_y / 2 + conv_integer(pi_ppu_scroll_y);
                else
                    reg_prf_y <= (reg_vga_y + 1) / 2 + conv_integer(pi_ppu_scroll_y);
                end if;
            else
                reg_prf_y <= 0;
            end if;
        end if;--if (pi_rst_n = '0') then
    end process;

    --vram access state machine (state transition)...
    vac_set_stat_p : process (pi_rst_n, pi_base_clk)
    begin
        if (pi_rst_n = '0') then
            reg_v_cur_state <= IDLE;
        elsif (rising_edge(pi_base_clk)) then
            reg_v_cur_state <= reg_v_next_state;
        end if;--if (pi_rst_n = '0') then
    end process;

    --state change to next.
    vac_next_stat_p : process (reg_v_cur_state, pi_rnd_en, pi_ppu_mask(PPUSBG), reg_nes_x, reg_nes_y)
function bg_process (
    pm_sbg          : in std_logic;
    pm_nes_x        : in integer range 0 to VGA_W_MAX - 1;
    pm_nes_y        : in integer range 0 to VGA_H_MAX - 1
    )return integer is
begin
    if (pm_sbg = '1'and
        (pm_nes_x <= HSCAN or pm_nes_x >= HSCAN_NEXT_START) and
        (pm_nes_y < VSCAN or pm_nes_y = VSCAN_NEXT_START)) then
        return 1;
    else
        return 0;
    end if;
end;

function is_idle (
    pm_sbg          : in std_logic;
    pm_nes_x        : in integer range 0 to VGA_W_MAX - 1;
    pm_nes_y        : in integer range 0 to VGA_H_MAX - 1
    )return integer is
begin
    if (pm_sbg = '0' or
        (pm_nes_x > HSCAN and pm_nes_x < HSCAN_NEXT_START) or
        (pm_nes_y >= VSCAN and pm_nes_y < VSCAN_NEXT_START)) then
        return 1;
    else
        return 0;
    end if;
end;
    begin
        case reg_v_cur_state is
            when IDLE =>
                if (bg_process(pi_ppu_mask(PPUSBG), reg_nes_x, reg_nes_y) = 1 and
                    pi_rnd_en(3) = '1' and
                    reg_nes_x mod 8 = 0) then
                    --start vram access process.
                    reg_v_next_state <= AD_SET0;
                else
                    reg_v_next_state <= reg_v_cur_state;
                end if;
            when AD_SET0 =>
                if (bg_process(pi_ppu_mask(PPUSBG), reg_nes_x, reg_nes_y) = 1 and
                    pi_rnd_en(0) = '1'
                ) then
                    reg_v_next_state <= AD_SET1;
                elsif (is_idle(pi_ppu_mask(PPUSBG), reg_nes_x, reg_nes_y) = 1) then
                    ---when nes_x=257, fall to idle
                    reg_v_next_state <= IDLE;
                else
                    reg_v_next_state <= reg_v_cur_state;
                end if;
            when AD_SET1 =>
                if (bg_process(pi_ppu_mask(PPUSBG), reg_nes_x, reg_nes_y) = 1 and
                    pi_rnd_en(1) = '1'
                ) then
                    reg_v_next_state <= AD_SET2;
                else
                    reg_v_next_state <= reg_v_cur_state;
                end if;
            when AD_SET2 =>
                if (bg_process(pi_ppu_mask(PPUSBG), reg_nes_x, reg_nes_y) = 1 and
                    pi_rnd_en(2) = '1'
                ) then
                    reg_v_next_state <= AD_SET3;
                else
                    reg_v_next_state <= reg_v_cur_state;
                end if;
            when AD_SET3 =>
                if (bg_process(pi_ppu_mask(PPUSBG), reg_nes_x, reg_nes_y) = 1 and
                    pi_rnd_en(3) = '1'
                ) then
                    reg_v_next_state <= REG_SET0;
                else
                    reg_v_next_state <= reg_v_cur_state;
                end if;
            when REG_SET0 =>
                if (bg_process(pi_ppu_mask(PPUSBG), reg_nes_x, reg_nes_y) = 1 and
                    pi_rnd_en(0) = '1'
                ) then
                    reg_v_next_state <= REG_SET1;
                else
                    reg_v_next_state <= reg_v_cur_state;
                end if;
            when REG_SET1 =>
                if (bg_process(pi_ppu_mask(PPUSBG), reg_nes_x, reg_nes_y) = 1 and
                    pi_rnd_en(1) = '1'
                ) then
                    reg_v_next_state <= REG_SET2;
                else
                    reg_v_next_state <= reg_v_cur_state;
                end if;
            when REG_SET2 =>
                if (bg_process(pi_ppu_mask(PPUSBG), reg_nes_x, reg_nes_y) = 1 and
                    pi_rnd_en(2) = '1'
                ) then
                    reg_v_next_state <= REG_SET3;
                else
                    reg_v_next_state <= reg_v_cur_state;
                end if;
            when REG_SET3 =>
                if (bg_process(pi_ppu_mask(PPUSBG), reg_nes_x, reg_nes_y) = 1 and
                    pi_rnd_en(3) = '1'
                ) then
                    reg_v_next_state <= AD_SET0;
                else
                    reg_v_next_state <= reg_v_cur_state;
                end if;
        end case;
    end process;

    po_rd_n         <= reg_v_rd_n;
    po_wr_n         <= reg_v_wr_n;
    po_v_addr       <= reg_v_addr;

    --vram r/w selector state machine...
    vac_main_stat_p : process (reg_v_cur_state)
    begin
        case reg_v_cur_state is
            when IDLE =>
                reg_v_rd_n  <= 'Z';
                reg_v_wr_n  <= 'Z';
            when AD_SET0 | AD_SET1 | REG_SET2 | REG_SET3 =>
                reg_v_rd_n  <= '1';
                reg_v_wr_n  <= '1';
            when AD_SET2 | AD_SET3 | REG_SET0 | REG_SET1 =>
                reg_v_rd_n  <= '0';
                reg_v_wr_n  <= '1';
        end case;
    end process;

    --vram address state machine...
    vaddr_stat_p : process (pi_rst_n, pi_base_clk)
function is_bg (
    pm_sbg          : in std_logic;
    pm_nes_x        : in integer range 0 to VGA_W_MAX - 1;
    pm_nes_y        : in integer range 0 to VGA_H_MAX - 1
    )return integer is
begin
    if (pm_sbg = '1'and
        (pm_nes_x <= HSCAN or pm_nes_x >= HSCAN_NEXT_START) and
        (pm_nes_y < VSCAN or pm_nes_y = VSCAN_NEXT_START)) then
        return 1;
    else
        return 0;
    end if;
end;
    begin
        if (pi_rst_n = '0') then
            reg_v_addr  <= (others => 'Z');
            reg_v_data    <= (others => 'Z');
        elsif (rising_edge(pi_base_clk)) then
            reg_v_data    <= pi_v_data;
            
            if (is_bg(pi_ppu_mask(PPUSBG), reg_nes_x, reg_nes_y) = 1) then
                ----fetch next tile byte.
                if (reg_prf_x mod 8 = 1) then
                    --vram addr is incremented every 8 cycle.
                    --name table at 0x2000
                    reg_v_addr(9 downto 0)
                        <= conv_std_logic_vector(reg_prf_y, 9)(7 downto 3)
                            & conv_std_logic_vector(reg_prf_x, 9)(7 downto 3);
                    reg_v_addr(13 downto 10) <= "10" & pi_ppu_ctrl(PPUBNA downto 0)
                                                    + ("000" & conv_std_logic_vector(reg_prf_x, 9)(8));
                ----fetch attr table byte.
                elsif (reg_prf_x mod 8 = 3) then
                    --attr table at 0x23c0
                    reg_v_addr(7 downto 0) <= "11000000" +
                            ("00" & conv_std_logic_vector(reg_prf_y, 9)(7 downto 5)
                                  & conv_std_logic_vector(reg_prf_x, 9)(7 downto 5));
                    reg_v_addr(13 downto 8) <= "10" &
                            pi_ppu_ctrl(PPUBNA downto 0) & "11"
                                + ("000" & conv_std_logic_vector(reg_prf_x, 9)(8) & "00");
                ----fetch pattern table low byte.
                elsif (reg_prf_x mod 8 = 5) then
                     --vram addr is incremented every 8 cycle.
                     reg_v_addr <= "0" & pi_ppu_ctrl(PPUBPA) &
                                          reg_disp_nt(7 downto 0)
                                        & "0" & conv_std_logic_vector(reg_prf_y, 9)(2 downto 0);
                ----fetch pattern table high byte.
                elsif (reg_prf_x mod 8 = 7) then
                     --vram addr is incremented every 8 cycle.
                     reg_v_addr <= "0" & pi_ppu_ctrl(PPUBPA) &
                                          reg_disp_nt(7 downto 0)
                                        & "0" & conv_std_logic_vector(reg_prf_y, 9)(2 downto 0)
                                        + "00000000001000";
                end if;
            end if;
        end if;--if (pi_rst_n = '0') then
    end process;

    --vram r/w selector state machine...
    bg_main_stat_p : process (reg_v_cur_state, reg_v_data)
    begin
        case reg_v_cur_state is
            when IDLE =>
                reg_disp_nt     <= (others => 'Z');
                reg_disp_attr   <= (others => 'Z');
                reg_disp_ptn_l  <= (others => 'Z');
                reg_disp_ptn_h  <= (others => 'Z');
            when AD_SET0 | AD_SET1 | REG_SET2 | AD_SET2 | AD_SET3 | REG_SET0 | REG_SET1 =>
--                reg_disp_nt     <= (others => 'Z');
--                reg_disp_attr   <= (others => 'Z');
--                reg_disp_ptn_l  <= (others => 'Z');
--                reg_disp_ptn_h  <= (others => 'Z');
            when REG_SET3 =>
                reg_disp_nt     <= reg_v_data;
                reg_disp_attr   <= reg_v_data;
                reg_disp_ptn_l  <= reg_v_data & "00000000";
                reg_disp_ptn_h  <= reg_v_data & "00000000";
        end case;
    end process;


    po_ppu_status   <= (others => '0');

    po_spr_ce_n     <= 'Z';
    po_spr_rd_n     <= 'Z';
    po_spr_wr_n     <= 'Z';
    po_spr_addr     <= (others => 'Z');

    po_r           <= (others => 'Z');
    po_g           <= (others => 'Z');
    po_b           <= (others => 'Z');
end rtl;

