library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.conv_std_logic_vector;
use ieee.std_logic_unsigned.all;
use work.motonesfpga_common.all;

entity ppu_render is 
    port (  clk         : in std_logic;
            mem_clk     : in std_logic;
            rst_n       : in std_logic;
            rd_n        : out std_logic;
            wr_n        : out std_logic;
            ale         : out std_logic;
            vram_ad     : inout std_logic_vector (7 downto 0);
            vram_a      : out std_logic_vector (13 downto 8);
            pos_x       : out std_logic_vector (8 downto 0);
            pos_y       : out std_logic_vector (8 downto 0);
            r           : out std_logic_vector (3 downto 0);
            g           : out std_logic_vector (3 downto 0);
            b           : out std_logic_vector (3 downto 0);
            ppu_ctrl        : in std_logic_vector (7 downto 0);
            ppu_mask        : in std_logic_vector (7 downto 0);
            read_status     : in std_logic;
            ppu_status      : out std_logic_vector (7 downto 0);
            ppu_scroll_x    : in std_logic_vector (7 downto 0);
            ppu_scroll_y    : in std_logic_vector (7 downto 0);
            r_nw            : in std_logic;
            oam_bus_ce_n    : in std_logic;
            plt_bus_ce_n    : in std_logic;
            oam_plt_addr    : in std_logic_vector (7 downto 0);
            oam_plt_data    : inout std_logic_vector (7 downto 0);
            v_bus_busy_n    : out std_logic
    );
end ppu_render;

architecture rtl of ppu_render is

component counter_register
    generic (
        dsize       : integer := 8;
        inc         : integer := 1
    );
    port (  clk         : in std_logic;
            rst_n       : in std_logic;
            ce_n        : in std_logic;
            we_n        : in std_logic;
            d           : in std_logic_vector(dsize - 1 downto 0);
            q           : out std_logic_vector(dsize - 1 downto 0)
    );
end component;

component shift_register
    generic (
        dsize : integer := 8;
        shift : integer := 1
    );
    port (  clk         : in std_logic;
            rst_n       : in std_logic;
            ce_n        : in std_logic;
            we_n        : in std_logic;
            d           : in std_logic_vector(dsize - 1 downto 0);
            q           : out std_logic_vector(dsize - 1 downto 0)
    );
end component;

component d_flip_flop
    generic (
            dsize : integer := 8
            );
    port (  
            clk     : in std_logic;
            res_n   : in std_logic;
            set_n   : in std_logic;
            we_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;

component tri_state_buffer
    generic (
            dsize : integer := 8
            );
    port (  
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;

component ram
    generic (abus_size : integer := 16; dbus_size : integer := 8);
    port (  
            clk               : in std_logic;
            ce_n, oe_n, we_n  : in std_logic;   --select pin active low.
            addr              : in std_logic_vector (abus_size - 1 downto 0);
            d_io              : inout std_logic_vector (dbus_size - 1 downto 0)
    );
end component;

component palette_ram
    generic (abus_size : integer := 16; dbus_size : integer := 8);
    port (  
            clk               : in std_logic;
            ce_n, oe_n, we_n  : in std_logic;   --select pin active low.
            addr              : in std_logic_vector (abus_size - 1 downto 0);
            d_io              : inout std_logic_vector (dbus_size - 1 downto 0)
    );
end component;

constant X_SIZE       : integer := 9;
constant dsize        : integer := 8;
constant asize        : integer := 14;
constant HSCAN_MAX    : integer := 341;
constant VSCAN_MAX    : integer := 262;
constant HSCAN        : integer := 256;
constant VSCAN        : integer := 240;
constant HSCAN_NEXT_START    : integer := 320;
constant HSCAN_NEXT_EXTRA    : integer := 336;


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

signal clk_n            : std_logic;

--timing adjust
signal bg_io_cnt        : std_logic_vector(0 downto 0);
signal spr_io_cnt       : std_logic_vector(0 downto 0);

--vram i/o
signal io_oe_n          : std_logic;
signal ah_oe_n          : std_logic;

signal cnt_x_res_n   : std_logic;
signal bg_cnt_res_n  : std_logic;
signal cnt_y_en_n    : std_logic;
signal cnt_y_res_n   : std_logic;

--current drawing position 340 x 261
signal cur_x            : std_logic_vector(X_SIZE - 1 downto 0);
signal cur_y            : std_logic_vector(X_SIZE - 1 downto 0);
--bg prefetch position (scroll + 16 cycle ahead of current pos)
--511 x 239 (or 255 x 479)
signal prf_x            : std_logic_vector(X_SIZE - 1 downto 0);
signal prf_y            : std_logic_vector(X_SIZE - 1 downto 0);

signal nt_we_n          : std_logic;
signal disp_nt          : std_logic_vector (dsize - 1 downto 0);

signal attr_ce_n        : std_logic;
signal attr_we_n        : std_logic;
signal attr_val         : std_logic_vector (dsize - 1 downto 0);
signal disp_attr_we_n   : std_logic;
signal disp_attr        : std_logic_vector (dsize - 1 downto 0);

signal ptn_l_we_n       : std_logic;
signal ptn_l_in         : std_logic_vector (dsize - 1 downto 0);
signal ptn_l_val        : std_logic_vector (dsize - 1 downto 0);
signal disp_ptn_l_in    : std_logic_vector (dsize * 2 - 1 downto 0);
signal disp_ptn_l       : std_logic_vector (dsize * 2 - 1 downto 0);

signal ptn_h_we_n       : std_logic;
signal ptn_h_in         : std_logic_vector (dsize * 2 - 1 downto 0);
signal disp_ptn_h       : std_logic_vector (dsize * 2 - 1 downto 0);

--signals for palette / oam access from cpu
signal r_n              : std_logic;
signal vram_addr        : std_logic_vector (asize - 1 downto 0);

--palette
signal plt_ram_ce_n     : std_logic;
signal plt_r_n          : std_logic;
signal plt_w_n          : std_logic;
signal plt_addr         : std_logic_vector (4 downto 0);
signal plt_data         : std_logic_vector (dsize - 1 downto 0);

--primari / secondary oam
signal oam_ram_ce_n     : std_logic;
signal oam_r_n          : std_logic;
signal oam_w_n          : std_logic;
signal oam_addr         : std_logic_vector (dsize - 1 downto 0);
signal oam_data         : std_logic_vector (dsize - 1 downto 0);

signal s_oam_ram_ce_n   : std_logic;
signal s_oam_r_n        : std_logic;
signal s_oam_w_n        : std_logic;
signal s_oam_addr_cpy_ce_n      : std_logic;
signal s_oam_addr_cpy_n         : std_logic;
signal s_oam_addr       : std_logic_vector (4 downto 0);
signal s_oam_addr_cpy   : std_logic_vector (4 downto 0);
signal s_oam_data       : std_logic_vector (dsize - 1 downto 0);

signal p_oam_cnt_res_n  : std_logic;
signal p_oam_cnt_ce_n   : std_logic;
signal p_oam_cnt_wrap_n : std_logic;
signal s_oam_cnt_ce_n   : std_logic;
signal p_oam_cnt        : std_logic_vector (dsize - 1 downto 0);
signal s_oam_cnt        : std_logic_vector (4 downto 0);
signal p_oam_addr_in    : std_logic_vector (dsize - 1 downto 0);
signal oam_ev_status    : std_logic_vector (2 downto 0);

--oam evaluation status
constant EV_STAT_COMP       : std_logic_vector (2 downto 0) := "000";
constant EV_STAT_CP1        : std_logic_vector (2 downto 0) := "001";
constant EV_STAT_CP2        : std_logic_vector (2 downto 0) := "010";
constant EV_STAT_CP3        : std_logic_vector (2 downto 0) := "011";
constant EV_STAT_PRE_COMP   : std_logic_vector (2 downto 0) := "100";

----------sprite registers.
type oam_pin_array    is array (0 to 7) of std_logic;
type oam_reg_array    is array (0 to 7) of std_logic_vector (dsize - 1 downto 0);

signal spr_x_we_n       : oam_pin_array;
signal spr_x_ce_n       : oam_pin_array;
signal spr_attr_we_n    : oam_pin_array;
signal spr_ptn_l_we_n   : oam_pin_array;
signal spr_ptn_h_we_n   : oam_pin_array;
signal spr_ptn_ce_n     : oam_pin_array;

signal spr_x_cnt        : oam_reg_array;
signal spr_attr         : oam_reg_array;
signal spr_ptn_l        : oam_reg_array;
signal spr_ptn_h        : oam_reg_array;

signal spr_y_we_n       : std_logic;
signal spr_tile_we_n    : std_logic;
signal spr_y_tmp        : std_logic_vector (dsize - 1 downto 0);
signal spr_tile_tmp     : std_logic_vector (dsize - 1 downto 0);
signal spr_ptn_in       : std_logic_vector (dsize - 1 downto 0);


begin

    clk_n <= not clk;

    ale <= bg_io_cnt(0) when ppu_mask(PPUSBG) = '1' and
                (cur_y < conv_std_logic_vector(VSCAN, X_SIZE) or 
                cur_y = conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE)) and
                (cur_x <= conv_std_logic_vector(HSCAN, X_SIZE) or
                cur_x > conv_std_logic_vector(HSCAN_NEXT_START, X_SIZE)) else
           spr_io_cnt(0) when ppu_mask(PPUSSP) = '1' and
                (cur_y < conv_std_logic_vector(VSCAN, X_SIZE) or 
                cur_y = conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE)) and
                (cur_x > conv_std_logic_vector(256, X_SIZE) and 
                cur_x <= conv_std_logic_vector(HSCAN_NEXT_START, X_SIZE)) else
           'Z';

    rd_n <= bg_io_cnt(0) when ppu_mask(PPUSBG) = '1' and
                (cur_y < conv_std_logic_vector(VSCAN, X_SIZE) or 
                cur_y = conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE)) and
                (cur_x <= conv_std_logic_vector(HSCAN, X_SIZE) or
                cur_x > conv_std_logic_vector(HSCAN_NEXT_START, X_SIZE)) else
           spr_io_cnt(0) when ppu_mask(PPUSSP) = '1' and
                (cur_y < conv_std_logic_vector(VSCAN, X_SIZE) or 
                cur_y = conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE)) and
                (cur_x > conv_std_logic_vector(256, X_SIZE) and 
                cur_x <= conv_std_logic_vector(HSCAN_NEXT_START, X_SIZE)) else
            'Z';
    wr_n <= '1' when (ppu_mask(PPUSBG) = '1' or ppu_mask(PPUSSP) = '1') and
                (cur_y < conv_std_logic_vector(VSCAN, X_SIZE) or 
                cur_y = conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE)) else
            'Z';
    io_oe_n <= not bg_io_cnt(0) when ppu_mask(PPUSBG) = '1' and
                (cur_y < conv_std_logic_vector(VSCAN, X_SIZE) or 
                cur_y = conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE)) and
                (cur_x <= conv_std_logic_vector(HSCAN, X_SIZE) or
                cur_x > conv_std_logic_vector(HSCAN_NEXT_START, X_SIZE)) else
           not spr_io_cnt(0) when ppu_mask(PPUSSP) = '1' and
                (cur_y < conv_std_logic_vector(VSCAN, X_SIZE) or 
                cur_y = conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE)) and
                (cur_x > conv_std_logic_vector(256, X_SIZE) and 
                cur_x <= conv_std_logic_vector(HSCAN_NEXT_START, X_SIZE)) else
               '1';
    ah_oe_n <= '0' when (ppu_mask(PPUSBG) = '1' or ppu_mask(PPUSSP) = '1') and
                (cur_y < conv_std_logic_vector(VSCAN, X_SIZE) or 
                cur_y = conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE)) else
              '1';
    v_bus_busy_n <= ah_oe_n;

    bg_io_cnt_inst : counter_register generic map (1, 1)
            port map (clk, bg_cnt_res_n, '0', '1', (others => '0'), bg_io_cnt);
    spr_io_cnt_inst : counter_register generic map (1, 1)
            port map (clk, cnt_x_res_n, '0', '1', (others => '0'), spr_io_cnt);

    ---bg prefetch x pos is 16 + scroll cycle ahead of current pos.
    prf_x <= cur_x + ppu_scroll_x + "000010000" 
                    when cur_x < conv_std_logic_vector(HSCAN, X_SIZE) else
             cur_x + ppu_scroll_x + "010111011"; -- +16 -341

    prf_y <= cur_y + ppu_scroll_y
                    when cur_x < conv_std_logic_vector(HSCAN, X_SIZE) and
                         cur_y + ppu_scroll_y <
                            conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE) else
             cur_y + ppu_scroll_y + "000000001" 
                    when cur_y + ppu_scroll_y <
                            conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE) else
             "000000000"; 

    --current x,y pos
    cur_x_inst : counter_register generic map (X_SIZE, 1)
            port map (clk_n, cnt_x_res_n, '0', '1', (others => '0'), cur_x);
    cur_y_inst : counter_register generic map (X_SIZE, 1)
            port map (clk_n, cnt_y_res_n, cnt_y_en_n, '1', (others => '0'), cur_y);

    nt_inst : d_flip_flop generic map(dsize)
            port map (clk_n, rst_n, '1', nt_we_n, vram_ad, disp_nt);

    at_inst : d_flip_flop generic map(dsize)
            port map (clk_n, rst_n, '1', attr_we_n, vram_ad, attr_val);

    disp_at_inst : shift_register generic map(dsize, 2)
            port map (clk_n, rst_n, attr_ce_n, disp_attr_we_n, attr_val, disp_attr);

    --chr rom data's bit is stored in opposite direction.
    --reverse bit when loading...
    ptn_l_in <= (vram_ad(0) & vram_ad(1) & vram_ad(2) & vram_ad(3) & 
                 vram_ad(4) & vram_ad(5) & vram_ad(6) & vram_ad(7));
    ptn_h_in <= (vram_ad(0) & vram_ad(1) & vram_ad(2) & vram_ad(3) & 
                 vram_ad(4) & vram_ad(5) & vram_ad(6) & vram_ad(7)) & 
                disp_ptn_h (dsize downto 1);

    ptn_l_inst : d_flip_flop generic map(dsize)
            port map (clk_n, rst_n, '1', ptn_l_we_n, ptn_l_in, ptn_l_val);

    disp_ptn_l_in <= ptn_l_val & disp_ptn_l (dsize downto 1);
    disp_ptn_l_inst : shift_register generic map(dsize * 2, 1)
            port map (clk_n, rst_n, '0', ptn_h_we_n, disp_ptn_l_in, disp_ptn_l);

    ptn_h_inst : shift_register generic map(dsize * 2, 1)
            port map (clk_n, rst_n, '0', ptn_h_we_n, ptn_h_in, disp_ptn_h);

    --vram i/o
    vram_io_buf : tri_state_buffer generic map (dsize)
            port map (io_oe_n, vram_addr(dsize - 1 downto 0), vram_ad);

    vram_a_buf : tri_state_buffer generic map (6)
            port map (ah_oe_n, vram_addr(asize - 1 downto dsize), vram_a);

    pos_x <= cur_x;
    pos_y <= cur_y;

    ---palette ram
    r_n <= not r_nw;

    plt_ram_ce_n <= clk when plt_bus_ce_n = '0' and r_nw = '0' else 
                    '0' when plt_bus_ce_n = '0' and r_nw = '1' else
                    '0' when ppu_mask(PPUSBG) = '1' and 
                            (cur_x < conv_std_logic_vector(HSCAN, X_SIZE)) and 
                            (cur_y < conv_std_logic_vector(VSCAN, X_SIZE)) else
                    '1';

    plt_addr <= oam_plt_addr(4 downto 0) when plt_bus_ce_n = '0' else
                "1" & spr_attr(0)(1 downto 0) & spr_ptn_h(0)(0) & spr_ptn_l(0)(0)
                    when ppu_mask(PPUSSP) = '1' and
                        (cur_x < conv_std_logic_vector(HSCAN, X_SIZE)) and
                        (cur_y < conv_std_logic_vector(VSCAN, X_SIZE)) and
                        spr_x_cnt(0) = "00000000" and 
                        (spr_ptn_h(0)(0) or spr_ptn_l(0)(0)) = '1' else
                "1" & spr_attr(1)(1 downto 0) & spr_ptn_h(1)(0) & spr_ptn_l(1)(0)
                    when ppu_mask(PPUSSP) = '1' and
                        (cur_x < conv_std_logic_vector(HSCAN, X_SIZE)) and
                        (cur_y < conv_std_logic_vector(VSCAN, X_SIZE)) and
                        spr_x_cnt(1) = "00000000" and 
                        (spr_ptn_h(1)(0) or spr_ptn_l(1)(0)) = '1' else
                "1" & spr_attr(2)(1 downto 0) & spr_ptn_h(2)(0) & spr_ptn_l(2)(0)
                    when ppu_mask(PPUSSP) = '1' and 
                        (cur_x < conv_std_logic_vector(HSCAN, X_SIZE)) and
                        (cur_y < conv_std_logic_vector(VSCAN, X_SIZE)) and
                        spr_x_cnt(2) = "00000000" and
                        (spr_ptn_h(2)(0) or spr_ptn_l(2)(0)) = '1' else
                "1" & spr_attr(3)(1 downto 0) & spr_ptn_h(3)(0) & spr_ptn_l(3)(0)
                    when ppu_mask(PPUSSP) = '1' and
                        (cur_x < conv_std_logic_vector(HSCAN, X_SIZE)) and
                        (cur_y < conv_std_logic_vector(VSCAN, X_SIZE)) and
                        spr_x_cnt(3) = "00000000" and
                        (spr_ptn_h(3)(0) or spr_ptn_l(3)(0)) = '1' else
                "1" & spr_attr(4)(1 downto 0) & spr_ptn_h(4)(0) & spr_ptn_l(4)(0)
                    when ppu_mask(PPUSSP) = '1' and
                        (cur_x < conv_std_logic_vector(HSCAN, X_SIZE)) and
                        (cur_y < conv_std_logic_vector(VSCAN, X_SIZE)) and
                        spr_x_cnt(4) = "00000000" and
                        (spr_ptn_h(4)(0) or spr_ptn_l(4)(0)) = '1' else
                "1" & spr_attr(5)(1 downto 0) & spr_ptn_h(5)(0) & spr_ptn_l(5)(0)
                    when ppu_mask(PPUSSP) = '1' and
                        (cur_x < conv_std_logic_vector(HSCAN, X_SIZE)) and
                        (cur_y < conv_std_logic_vector(VSCAN, X_SIZE)) and
                        spr_x_cnt(5) = "00000000" and
                        (spr_ptn_h(5)(0) or spr_ptn_l(5)(0)) = '1' else
                "1" & spr_attr(6)(1 downto 0) & spr_ptn_h(6)(0) & spr_ptn_l(6)(0)
                    when ppu_mask(PPUSSP) = '1' and
                        (cur_x < conv_std_logic_vector(HSCAN, X_SIZE)) and
                        (cur_y < conv_std_logic_vector(VSCAN, X_SIZE)) and
                        spr_x_cnt(6) = "00000000" and
                        (spr_ptn_h(6)(0) or spr_ptn_l(6)(0)) = '1' else
                "1" & spr_attr(7)(1 downto 0) & spr_ptn_h(7)(0) & spr_ptn_l(7)(0)
                    when ppu_mask(PPUSSP) = '1' and
                        (cur_x < conv_std_logic_vector(HSCAN, X_SIZE)) and
                        (cur_y < conv_std_logic_vector(VSCAN, X_SIZE)) and
                        spr_x_cnt(7) = "00000000" and
                        (spr_ptn_h(7)(0) or spr_ptn_l(7)(0)) = '1' else
                "0" & disp_attr(1 downto 0) & disp_ptn_h(0) & disp_ptn_l(0) 
                    when ppu_mask(PPUSBG) = '1' and cur_y(4) = '0' and
                        ((disp_ptn_h(0) or disp_ptn_l(0)) = '1') and
                        (cur_x < conv_std_logic_vector(HSCAN, X_SIZE)) and
                        (cur_y < conv_std_logic_vector(VSCAN, X_SIZE)) else
                "0" & disp_attr(5 downto 4) & disp_ptn_h(0) & disp_ptn_l(0)
                    when ppu_mask(PPUSBG) = '1' and cur_y(4) = '1' and
                        ((disp_ptn_h(0) or disp_ptn_l(0)) = '1') and
                        (cur_x < conv_std_logic_vector(HSCAN, X_SIZE)) and
                        (cur_y < conv_std_logic_vector(VSCAN, X_SIZE)) else
                ---else: no output color >> universal bg color output.
                --0x3f00 is the universal bg palette.
                (others => '0');    

    plt_r_n <= not r_nw when plt_bus_ce_n = '0' else
                '0' when ppu_mask(PPUSBG) = '1' else
                '1';
    plt_w_n <= r_nw when plt_bus_ce_n = '0' else
                '1';
    plt_d_buf_w : tri_state_buffer generic map (dsize)
            port map (r_nw, oam_plt_data, plt_data);
    plt_d_buf_r : tri_state_buffer generic map (dsize)
            port map (r_n, plt_data, oam_plt_data);
    palette_inst : palette_ram generic map (5, dsize)
            port map (mem_clk, plt_ram_ce_n, plt_r_n, plt_w_n, plt_addr, plt_data);

    ---primary oam
    oam_ram_ce_n <= clk when oam_bus_ce_n = '0' and r_nw = '0' else
                    '0' when oam_bus_ce_n = '0' and r_nw = '1' else
                    '0' when ppu_mask(PPUSSP) = '1' and
                             cur_x > conv_std_logic_vector(64, X_SIZE) and
                             cur_x <= conv_std_logic_vector(256, X_SIZE) and
                             p_oam_cnt_wrap_n = '1' else
                    '1';
    oam_addr <= oam_plt_addr when oam_bus_ce_n = '0' else
                p_oam_addr_in when ppu_mask(PPUSSP) = '1' and 
                        (cur_y < conv_std_logic_vector(VSCAN, X_SIZE) or 
                        cur_y = conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE)) and
                         cur_x > conv_std_logic_vector(64, X_SIZE) and 
                         cur_x <= conv_std_logic_vector(256, X_SIZE) else
                (others => 'Z');
    oam_r_n <= not r_nw when oam_bus_ce_n = '0' else
                '0' when ppu_mask(PPUSSP) = '1' and 
                        (cur_y < conv_std_logic_vector(VSCAN, X_SIZE) or 
                        cur_y = conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE)) and
                         cur_x > conv_std_logic_vector(64, X_SIZE) and 
                         cur_x <= conv_std_logic_vector(256, X_SIZE) else
                '1';
    oam_w_n <= r_nw when oam_bus_ce_n = '0' else
                '1';
    oam_d_buf_w : tri_state_buffer generic map (dsize)
            port map (r_nw, oam_plt_data, oam_data);
    oam_d_buf_r : tri_state_buffer generic map (dsize)
            port map (r_n, oam_data, oam_plt_data);
    primary_oam_inst : ram generic map (dsize, dsize)
            port map (mem_clk, oam_ram_ce_n, oam_r_n, oam_w_n, oam_addr, oam_data);

    ---secondary oam
    p_oam_cnt_inst : counter_register generic map (dsize, 4)
            port map (clk_n, p_oam_cnt_res_n, p_oam_cnt_ce_n, '1', (others => '0'), p_oam_cnt);
    s_oam_cnt_inst : counter_register generic map (5, 1)
            port map (clk_n, p_oam_cnt_res_n, s_oam_cnt_ce_n, '1', (others => '0'), s_oam_cnt);
    s_oam_addr_cpy_inst : counter_register generic map (5, 1)
            port map (clk_n, p_oam_cnt_res_n, s_oam_addr_cpy_ce_n, 
                    '1', (others => '0'), s_oam_addr_cpy);

    s_oam_ram_ce_n <= clk when ppu_mask(PPUSSP) = '1' and cur_x(0) = '1' and
                                cur_x > "000000001" and
                                cur_x <= conv_std_logic_vector(64, X_SIZE) else
                      clk when ppu_mask(PPUSSP) = '1' and cur_x(0) = '1' and
                                cur_x > conv_std_logic_vector(64, X_SIZE) and
                                cur_x <= conv_std_logic_vector(256, X_SIZE) and
                                p_oam_cnt_wrap_n = '1' else
                      '0' when ppu_mask(PPUSSP) = '1' and
                                cur_x > conv_std_logic_vector(256, X_SIZE) and
                                cur_x <= conv_std_logic_vector(320, X_SIZE) and
                                s_oam_addr_cpy_n = '0' else
                      '1';

    secondary_oam_inst : ram generic map (5, dsize)
            port map (mem_clk, s_oam_ram_ce_n, s_oam_r_n, s_oam_w_n, s_oam_addr, s_oam_data);

    spr_y_inst : d_flip_flop generic map(dsize)
            port map (clk_n, p_oam_cnt_res_n, '1', spr_y_we_n, s_oam_data, spr_y_tmp);
    spr_tile_inst : d_flip_flop generic map(dsize)
            port map (clk_n, p_oam_cnt_res_n, '1', spr_tile_we_n, s_oam_data, spr_tile_tmp);


   --reverse bit when NOT SPRHFL is set (.nes file format bit endian).
   spr_ptn_in <= vram_ad when spr_attr(conv_integer(s_oam_addr_cpy(4 downto 2)))(SPRHFL) = '1' else
                (vram_ad(0) & vram_ad(1) & vram_ad(2) & vram_ad(3) & 
                 vram_ad(4) & vram_ad(5) & vram_ad(6) & vram_ad(7));
    --array instances...
    spr_inst : for i in 0 to 7 generate
        spr_x_inst : counter_register generic map(dsize, 16#ff#)
                port map (clk_n, rst_n, spr_x_ce_n(i), spr_x_we_n(i), s_oam_data, spr_x_cnt(i));

        spr_attr_inst : d_flip_flop generic map(dsize)
                port map (clk_n, rst_n, '1', spr_attr_we_n(i), s_oam_data, spr_attr(i));

        spr_ptn_l_inst : shift_register generic map(dsize, 1)
                port map (clk_n, rst_n, spr_ptn_ce_n(i), spr_ptn_l_we_n(i), spr_ptn_in, spr_ptn_l(i));

        spr_ptn_h_inst : shift_register generic map(dsize, 1)
                port map (clk_n, rst_n, spr_ptn_ce_n(i), spr_ptn_h_we_n(i), spr_ptn_in, spr_ptn_h(i));
    end generate;

    clk_p : process (rst_n, clk, read_status)

procedure output_rgb is
variable pl_addr : integer;
variable pl_index : integer;
variable dot_output : boolean;
begin
    dot_output := false;

    --first show sprite.
    if (ppu_mask(PPUSSP) = '1') then
        for i in 0 to 7 loop
            if (spr_x_cnt(i) = "00000000") then
                if ((spr_ptn_h(i)(0) or spr_ptn_l(i)(0)) = '1') then
                    dot_output := true;
                    exit;
                end if;
            end if;
        end loop;
    end if;

    if (dot_output = true and ppu_mask(PPUSBG) = '1' and 
            (disp_ptn_h(0) or disp_ptn_l(0)) = '1') then
        --raise sprite 0 hit.
        ppu_status(ST_SP0) <= '1';
    end if;

    --first color in the palette is transparent color.
    if (ppu_mask(PPUSBG) = '1' and dot_output = false and 
            (disp_ptn_h(0) or disp_ptn_l(0)) = '1') then
        dot_output := true;
--        d_print("output_rgb");
--        d_print("pl_addr:" & conv_hex8(pl_addr));
--        d_print("pl_index:" & conv_hex8(pl_index));
    end if;

    --if or if not bg/sprite is shown, output color anyway 
    --sinse universal bg color is included..
    pl_index := conv_integer(plt_data(5 downto 0));
    b <= nes_color_palette(pl_index) (11 downto 8);
    g <= nes_color_palette(pl_index) (7 downto 4);
    r <= nes_color_palette(pl_index) (3 downto 0);
--    d_print("rgb:" &
--        conv_hex8(nes_color_palette(pl_index) (11 downto 8)) &
--        conv_hex8(nes_color_palette(pl_index) (7 downto 4)) &
--        conv_hex8(nes_color_palette(pl_index) (3 downto 0)));
end;

    begin
        if (rst_n = '0') then
            cnt_x_res_n <= '0';
            cnt_y_res_n <= '0';
            nt_we_n <= '1';
            bg_cnt_res_n <= '0';

            ppu_status <= (others => '0');

            b <= (others => '0');
            g <= (others => '0');
            r <= (others => '0');
        else
--            if (clk'event) then
--                --x pos reset.
--                if (clk = '0' and 
--                        cur_x = conv_std_logic_vector(HSCAN_MAX - 1, X_SIZE)) then
--                    cnt_x_res_n <= '0';
--
--                    --y pos reset.
--                    if (cur_y = conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE)) then
--                        cnt_y_res_n <= '0';
--                    else
--                        cnt_y_res_n <= '1';
--                    end if;
--                else
--                    cnt_x_res_n <= '1';
--                    cnt_y_res_n <= '1';
--                end if;
--
--                if (clk = '0' and 
--                        ppu_scroll_x(0) = '0' and cur_x = conv_std_logic_vector(HSCAN, X_SIZE)) then
--                    bg_cnt_res_n <= '0';
--                elsif (clk = '0' and 
--                        ppu_scroll_x(0) = '1' and cur_x = conv_std_logic_vector(HSCAN - 1, X_SIZE)) then
--                    bg_cnt_res_n <= '0';
--                else
--                    bg_cnt_res_n <= '1';
--                end if;
--            end if; --if (clk'event) then

            if (clk'event and clk = '1') then
                --y pos increment.
                if (cur_x = conv_std_logic_vector(HSCAN_MAX - 1, X_SIZE)) then
                    cnt_y_en_n <= '0';
                else
                    cnt_y_en_n <= '1';
                end if;
            end if; --if (clk'event) then

            if (clk'event and clk = '0') then
                d_print("-");
            end if;

            if (clk'event and clk = '1') then

                --fetch bg pattern and display.
                if (ppu_mask(PPUSBG) = '1' and 
                        (cur_x <= conv_std_logic_vector(HSCAN, X_SIZE) or
                        cur_x > conv_std_logic_vector(HSCAN_NEXT_START, X_SIZE)) and
                        (cur_y < conv_std_logic_vector(VSCAN, X_SIZE) or 
                        cur_y = conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE))) then
                    --visible area bg image

                    d_print("*");
                    d_print("cur_x: " & conv_hex16(conv_integer(cur_x)));
                    d_print("cur_y: " & conv_hex16(conv_integer(cur_y)));

                    ----fetch next tile byte.
                    if (prf_x (2 downto 0) = "001") then
                        --vram addr is incremented every 8 cycle.
                        --name table at 0x2000
                        vram_addr(9 downto 0) 
                            <= prf_y(dsize - 1 downto 3) 
                                & prf_x(dsize - 1 downto 3);
                        vram_addr(asize - 1 downto 10) <= "10" & ppu_ctrl(PPUBNA downto 0) 
                                                        + ("000" & prf_x(dsize));
                    end if;
                    if (prf_x (2 downto 0) = "010") then
                        nt_we_n <= '0';
                    else
                        nt_we_n <= '1';
                    end if;

                    --TODO must load 8 cycle each for the first two tiles!!!
                    ----fetch attr table byte.
                    if (prf_x (4 downto 0) = "00011") then
                        --attribute table is loaded every 32 cycle.
                        --attr table at 0x23c0
                        vram_addr(dsize - 1 downto 0) <= "11000000" +
                                ("00" & prf_y(7 downto 5) & prf_x(7 downto 5));
                        vram_addr(asize - 1 downto dsize) <= "10" &
                                ppu_ctrl(PPUBNA downto 0) & "11"
                                    + ("000" & prf_x(dsize) & "00");
                    end if;
                    if (prf_x (4 downto 0) = "00100") then
                        attr_we_n <= '0';
                    else
                        attr_we_n <= '1';
                    end if;
                    if (prf_x (4 downto 0) = "10000") then
                        disp_attr_we_n <= '0';
                    else
                        disp_attr_we_n <= '1';
                    end if;
                    ---attribute is shifted every 16 bit.
                    if (prf_x (3 downto 0) = "0000") then
                        attr_ce_n <= '0';
                    else
                        attr_ce_n <= '1';
                    end if;
                    
                        ----fetch pattern table low byte.
                        if (prf_x (2 downto 0) = "101") then
                            --vram addr is incremented every 8 cycle.
                            vram_addr <= "0" & ppu_ctrl(PPUBPA) & 
                                            disp_nt(dsize - 1 downto 0) 
                                                & "0"  & prf_y(2  downto 0);
                        end if;
                        if (prf_x (2 downto 0) = "110") then
                            ptn_l_we_n <= '0';
                        else
                            ptn_l_we_n <= '1';
                        end if;

                        ----fetch pattern table high byte.
                        if (prf_x (2 downto 0) = "111") then
                            --vram addr is incremented every 8 cycle.
                            vram_addr <= "0" & ppu_ctrl(PPUBPA) & 
                                            disp_nt(dsize - 1 downto 0) 
                                                & "0"  & prf_y(2 downto 0) + "00000000001000";
                        end if;
                        if (prf_x (2 downto 0) = "000") then
                            ptn_h_we_n <= '0';
                        else
                            ptn_h_we_n <= '1';
                        end if;

                end if;--if (ppu_mask(PPUSBG) = '1') and

                --fetch sprite and display.
                if (ppu_mask(PPUSSP) = '1' and
                        (cur_y < conv_std_logic_vector(VSCAN, X_SIZE) or 
                        cur_y = conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE))) then
                    --secondary oam clear
                    if (cur_x /= "000000000" and cur_x <= conv_std_logic_vector(64, X_SIZE)) then
                        if (cur_x(0) = '0') then
                            --write secondary oam on even cycle
                            s_oam_r_n <= '1';
                            s_oam_w_n <= '0';
                            s_oam_addr <= cur_x(5 downto 1);
                            s_oam_data <= (others => '1');
                        end if;
                        p_oam_cnt_res_n <= '0';
                        p_oam_cnt_ce_n <= '1';
                        s_oam_cnt_ce_n <= '1';
                        p_oam_cnt_wrap_n <= '1';
                        oam_ev_status <= EV_STAT_COMP;

                    --sprite evaluation and secondary oam copy.
                    elsif (cur_x > conv_std_logic_vector(64, X_SIZE) and 
                            cur_x <= conv_std_logic_vector(256, X_SIZE)) then
                        p_oam_cnt_res_n <= '1';

                        --TODO: sprite evaluation is simplified!!
                        --not complying the original NES spec at
                        --http://wiki.nesdev.com/w/index.php/PPU_sprite_evaluation
                        --e.g., when overflow happens, it just ignore subsequent entry.
                        --old secondary sprite entry.
                        if (p_oam_cnt = "00000000" and cur_x > conv_std_logic_vector(192, X_SIZE)) then
                            p_oam_cnt_wrap_n <= '0';
                        end if;

                        --odd cycle copy from primary oam
                        if (cur_x(0) = '1') then
                            if (oam_ev_status = EV_STAT_COMP) then
                                p_oam_addr_in <= p_oam_cnt;
                                p_oam_cnt_ce_n <= '1';
                                s_oam_cnt_ce_n <= '1';
                            elsif (oam_ev_status = EV_STAT_CP1) then
                                p_oam_addr_in <= p_oam_cnt + "00000001";
                                s_oam_cnt_ce_n <= '1';

                            elsif (oam_ev_status = EV_STAT_CP2) then
                                p_oam_addr_in <= p_oam_cnt + "00000010";
                                s_oam_cnt_ce_n <= '1';

                            elsif (oam_ev_status = EV_STAT_CP3) then
                                oam_ev_status <= EV_STAT_PRE_COMP;
                                p_oam_addr_in <= p_oam_cnt + "00000011";
                                s_oam_cnt_ce_n <= '1';
                            end if;
                        else
                        --even cycle copy to secondary oam (if y is in range.)
                            s_oam_r_n <= '1';
                            s_oam_w_n <= '0';
                            s_oam_addr <= s_oam_cnt;
                            s_oam_data <= oam_data;

                            if (oam_ev_status = EV_STAT_COMP) then
                                --check y range.
                                if (cur_y < "000000110" and oam_data <= cur_y + "000000001") or 
                                    (cur_y >= "000000110" and oam_data <= cur_y + "000000001" and 
                                             oam_data >= cur_y - "000000110") then
                                    oam_ev_status <= EV_STAT_CP1;
                                    s_oam_cnt_ce_n <= '0';
                                    --copy remaining oam entry.
                                    p_oam_cnt_ce_n <= '1';
                                else
                                    --goto next entry
                                    p_oam_cnt_ce_n <= '0';
                                end if;
                            elsif (oam_ev_status = EV_STAT_CP1) then
                                s_oam_cnt_ce_n <= '0';
                                oam_ev_status <= EV_STAT_CP2;
                            elsif (oam_ev_status = EV_STAT_CP2) then
                                s_oam_cnt_ce_n <= '0';
                                oam_ev_status <= EV_STAT_CP3;
                            elsif (oam_ev_status = EV_STAT_CP3) then
                                s_oam_cnt_ce_n <= '0';
                            elsif (oam_ev_status = EV_STAT_PRE_COMP) then
                                oam_ev_status <= EV_STAT_COMP;
                                s_oam_cnt_ce_n <= '0';
                                p_oam_cnt_ce_n <= '0';
                            end if;
                        end if;--if (cur_x(0) = '1') then

                        --prepare for next step
                        s_oam_addr_cpy_n <= '1';
                        spr_y_we_n <= '1';
                        spr_tile_we_n <= '1';
                        spr_x_we_n <= "11111111";
                        spr_attr_we_n <= "11111111";
                        spr_ptn_l_we_n <= "11111111";
                        spr_ptn_h_we_n <= "11111111";

                    --sprite pattern fetch
                    elsif (cur_x > conv_std_logic_vector(256, X_SIZE) and 
                            cur_x <= conv_std_logic_vector(HSCAN_NEXT_START, X_SIZE)) then

                        s_oam_addr_cpy_n <= '0';
                        s_oam_r_n <= '0';
                        s_oam_w_n <= '1';
                        s_oam_addr <= s_oam_addr_cpy;

                        ----fetch y-cordinate from secondary oam
                        if (cur_x (2 downto 0) = "001" ) then
                            s_oam_addr_cpy_ce_n <= '0';
                            spr_y_we_n <= '0';
                        else
                            spr_y_we_n <= '1';
                        end if;

                        ----fetch tile number
                        if (cur_x (2 downto 0) = "010" ) then
                            spr_tile_we_n <= '0';
                        else
                            spr_tile_we_n <= '1';
                        end if;

                        ----fetch attribute
                        if (cur_x (2 downto 0) = "011" ) then
                            spr_attr_we_n(conv_integer(s_oam_addr_cpy(4 downto 2))) <= '0';
                        else
                            spr_attr_we_n(conv_integer(s_oam_addr_cpy(4 downto 2))) <= '1';
                        end if;--if (cur_x (2 downto 0) = "010" ) then

                        ----fetch x-cordinate
                        if (cur_x (2 downto 0) = "100" ) then
                            s_oam_addr_cpy_ce_n <= '1';
                            spr_x_we_n(conv_integer(s_oam_addr_cpy(4 downto 2))) <= '0';
                        else
                            spr_x_we_n(conv_integer(s_oam_addr_cpy(4 downto 2))) <= '1';
                        end if;

                        ----fetch pattern table low byte.
                        if (cur_x (2 downto 0) = "101" ) then
                            if (spr_attr(conv_integer(s_oam_addr_cpy(4 downto 2)))(SPRVFL) = '0') then
                                vram_addr <= "0" & ppu_ctrl(PPUSPA) & 
                                            spr_tile_tmp(dsize - 1 downto 0) & "0" & 
                                            (cur_y(2 downto 0) + "001" - spr_y_tmp(2 downto 0));
                            else
                                --flip sprite vertically.
                                vram_addr <= "0" & ppu_ctrl(PPUSPA) & 
                                            spr_tile_tmp(dsize - 1 downto 0) & "0" & 
                                            (spr_y_tmp(2 downto 0) - cur_y(2 downto 0) - "010");
                            end if;
                        end if;

                        if (cur_x (2 downto 0) = "110" ) then
                            spr_ptn_l_we_n(conv_integer(s_oam_addr_cpy(4 downto 2))) <= '0';
                        else
                            spr_ptn_l_we_n(conv_integer(s_oam_addr_cpy(4 downto 2))) <= '1';
                        end if;

                        ----fetch pattern table high byte.
                        if (cur_x (2 downto 0) = "111" ) then
                            if (spr_attr(conv_integer(s_oam_addr_cpy(4 downto 2)))(SPRVFL) = '0') then
                                vram_addr <= "0" & ppu_ctrl(PPUSPA) & 
                                            spr_tile_tmp(dsize - 1 downto 0) & "0" & 
                                            (cur_y(2 downto 0) + "001" - spr_y_tmp(2 downto 0))
                                                + "00000000001000";
                            else
                                --flip sprite vertically.
                                vram_addr <= "0" & ppu_ctrl(PPUSPA) & 
                                            spr_tile_tmp(dsize - 1 downto 0) & "0"  & 
                                            (spr_y_tmp(2 downto 0) - cur_y(2 downto 0) - "010")
                                                + "00000000001000";
                            end if;
                        end if;

                        if (cur_x (2 downto 0) = "000") then
                            spr_ptn_h_we_n(conv_integer(s_oam_addr_cpy(4 downto 2))) <= '0';
                            s_oam_addr_cpy_ce_n <= '0';
                        else
                            spr_ptn_h_we_n(conv_integer(s_oam_addr_cpy(4 downto 2) - "001")) <= '1';
                        end if;

                    elsif (cur_x > conv_std_logic_vector(320, X_SIZE)) then
                        --clear last write enable.
                        spr_ptn_h_we_n <= "11111111";
                    end if;--if (cur_x /= "000000000" and cur_x <= conv_std_logic_vector(64, X_SIZE))

                    --display sprite.
                    if ((cur_x < conv_std_logic_vector(HSCAN, X_SIZE)) and
                        (cur_y < conv_std_logic_vector(VSCAN, X_SIZE))) then
                        --start counter.
                        if (cur_x = "000000000") then
                            spr_x_ce_n <= "00000000";
                        end if;

                        for i in 0 to 7 loop
                            if (spr_x_cnt(i) = "00000000") then
                                --active sprite, start shifting..
                                spr_x_ce_n(i) <= '1';
                                spr_ptn_ce_n(i) <= '0';
                            end if;
                        end loop;
                    else
                        spr_x_ce_n <= "11111111";
                        spr_ptn_ce_n <= "11111111";
                    end if; --if ((cur_x < conv_std_logic_vector(HSCAN, X_SIZE)) 
                end if; --if (ppu_mask(PPUSSP) = '1') then

                --output visible area only.
                if ((cur_x < conv_std_logic_vector(HSCAN, X_SIZE)) and
                    (cur_y < conv_std_logic_vector(VSCAN, X_SIZE))) then
                    --output image.
                    output_rgb;
                end if;

                --flag operation
                if ((cur_x = conv_std_logic_vector(1, X_SIZE)) and
                    (cur_y = conv_std_logic_vector(VSCAN + 1, X_SIZE))) then
                    --vblank start
                    ppu_status(ST_VBL) <= '1';
                elsif ((cur_x = conv_std_logic_vector(1, X_SIZE)) and
                    (cur_y = conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE))) then
                    ppu_status(ST_SP0) <= '0';
                    --vblank end
                    ppu_status(ST_VBL) <= '0';
                    --TODO: sprite overflow is not inplemented!
                    ppu_status(ST_SOF) <= '0';
                end if;
            end if; --if (clk'event and clk = '1') then

--            if (read_status'event and read_status = '1') then
--                --reading ppu status clears vblank bit.
--                ppu_status(ST_VBL) <= '0';
--            end if;

        end if;--if (rst_n = '0') then
    end process;

end rtl;

